import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'snackbar_helpers.dart';

class PrintPreviewScreen extends StatefulWidget {
  final List<String> cardUsernames;
  final String? templateImagePath;
  final String category;
  final int cardsPerPage;

  const PrintPreviewScreen({
    super.key,
    required this.cardUsernames,
    this.templateImagePath,
    this.category = 'general',
    this.cardsPerPage = 3,
  });

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen> {
  int _selectedCardsPerPage = 3;
  bool _isGenerating = false;
  List<pw.Widget> _previewCards = [];

  @override
  void initState() {
    super.initState();
    _selectedCardsPerPage = widget.cardsPerPage;
    _buildPreview();
  }

  @override
  void didUpdateWidget(PrintPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardUsernames != widget.cardUsernames ||
        oldWidget.cardsPerPage != widget.cardsPerPage) {
      _buildPreview();
    }
  }

  void _buildPreview() {
    _previewCards = widget.cardUsernames.map((username) {
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(
              username,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.category,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة الطباعة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _isGenerating ? null : _printCards,
            tooltip: 'طباعة',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isGenerating ? null : _sharePdf,
            tooltip: 'مشاركة PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // Cards per page selector
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
            child: Row(
              children: [
                const Icon(Icons.grid_view, size: 20),
                const SizedBox(width: 8),
                const Text('البطاقات في الصفحة:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('2'),
                  selected: _selectedCardsPerPage == 2,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCardsPerPage = 2);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('3'),
                  selected: _selectedCardsPerPage == 3,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCardsPerPage = 3);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('4'),
                  selected: _selectedCardsPerPage == 4,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCardsPerPage = 4);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('6'),
                  selected: _selectedCardsPerPage == 6,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCardsPerPage = 6);
                  },
                ),
              ],
            ),
          ),
          // Preview
          Expanded(
            child: _isGenerating
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _selectedCardsPerPage > 3 ? 3 : _selectedCardsPerPage,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: widget.cardUsernames.length,
                    itemBuilder: (context, index) {
                      return _previewCards[index];
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _printCards() async {
    setState(() => _isGenerating = true);

    try {
      final pdf = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'فشل الطباعة: ${e.toString()}');
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _isGenerating = true);

    try {
      final pdf = await _generatePdf();
      final bytes = await pdf.save();
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/cards_${widget.category}.pdf');
      await file.writeAsBytes(bytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'بطاقات WiFi - ${widget.category}',
        subject: 'WiFi Cards - ${widget.category}',
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'فشل المشاركة: ${e.toString()}');
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<pw.Document> _generatePdf() async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    int step = _selectedCardsPerPage;
    for (var i = 0; i < widget.cardUsernames.length; i += step) {
      final pageCards = widget.cardUsernames.sublist(
        i,
        i + step > widget.cardUsernames.length ? widget.cardUsernames.length : i + step,
      );

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.GridView(
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: _selectedCardsPerPage > 3 ? 3 : _selectedCardsPerPage,
              padding: const pw.EdgeInsets.all(20),
              children: pageCards.map((username) {
                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey, width: 1),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Icon(Icons.credit_card, size: 40, color: PdfColors.purple),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        username,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        widget.category,
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        dateStr,
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      );
    }

    return doc;
  }
}
