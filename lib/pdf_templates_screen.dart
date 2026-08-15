import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'edit_pdf_template_screen.dart';
import 'models/pdf_template.dart';
import 'services/pdf_template_storage.dart';
import 'snackbar_helpers.dart';
import 'theme/app_theme.dart';

export 'models/pdf_template.dart';

class PdfTemplatesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> profiles;

  const PdfTemplatesScreen({super.key, required this.profiles});

  @override
  State<PdfTemplatesScreen> createState() => _PdfTemplatesScreenState();
}

class _PdfTemplatesScreenState extends State<PdfTemplatesScreen> {
  List<PdfTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTemplates());
  }

  Future<void> _loadTemplates() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final templates = await PdfTemplateStorage.load();
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'تعذر تحميل قوالب PDF: $e');
    }
  }

  Future<void> _deleteTemplate(PdfTemplate templateToDelete) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف قالب الفئة "${templateToDelete.profileName}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'حذف',
              style: TextStyle(color: Theme.of(context).appColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await PdfTemplateStorage.delete(templateToDelete);
      if (!mounted) return;
      setState(() {
        _templates
            .removeWhere((template) => template.id == templateToDelete.id);
      });
      showSuccessSnackBar(context, 'تم حذف القالب بنجاح.');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'تعذر حذف القالب: $e');
    }
  }

  Future<void> _navigateAndReload(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
    if (mounted) await _loadTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة قوالب PDF'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmptyView()
              : RefreshIndicator(
                  onRefresh: _loadTemplates,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      return _buildTemplateCard(_templates[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndReload(
          EditPdfTemplateScreen(profiles: widget.profiles),
        ),
        tooltip: 'إضافة قالب جديد',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateCard(PdfTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 150,
                width: double.infinity,
                color: Theme.of(context).appColors.muted,
                child: Image.file(
                  File(template.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Theme.of(context).appColors.onSurfaceVariant,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'قالب فئة: ${template.profileName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'عدد الكروت بالصفحة: ${template.cardsPerPage}',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyMedium?.color ??
                    Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'معرّف القالب: ${template.id}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).appColors.muted,
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _deleteTemplate(template),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).appColors.error,
                    size: 20,
                  ),
                  label: Text(
                    'حذف',
                    style: TextStyle(
                      color: Theme.of(context).appColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _navigateAndReload(
                    EditPdfTemplateScreen(
                      profiles: widget.profiles,
                      existingTemplate: template,
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('تعديل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
              size: 80,
              color: Theme.of(context).appColors.muted,
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد قوالب محفوظة',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'اضغط على زر الإضافة (+) في الأسفل لإنشاء قالب PDF جديد خاص بك.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color ??
                    Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
