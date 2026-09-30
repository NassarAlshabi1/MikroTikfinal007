// lib/saved_files_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'snackbar_helpers.dart';

import 'card_list_screen.dart';
import 'theme/app_theme.dart';
import 'pdf_generator.dart'; // <-- ١. استيراد جديد
import 'services/pdf_template_storage.dart';

class SavedFile {
  final String path;
  final String profileName;
  final int userCount;
  final DateTime date;

  SavedFile({
    required this.path,
    required this.profileName,
    required this.userCount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'profileName': profileName,
        'userCount': userCount,
        'date': date.toIso8601String(),
      };

  factory SavedFile.fromJson(Map<String, dynamic> json) => SavedFile(
        path: json['path'],
        profileName: json['profileName'],
        userCount: json['userCount'],
        date: DateTime.parse(json['date']),
      );
}

class SavedFilesScreen extends StatefulWidget {
  const SavedFilesScreen({super.key});

  @override
  State<SavedFilesScreen> createState() => _SavedFilesScreenState();
}

class _SavedFilesScreenState extends State<SavedFilesScreen> {
  List<SavedFile> _savedFiles = [];
  bool _isLoading = true;

  // --- ٣. متغيرات جديدة لحالة الربط ---
  bool _isNetworkLinked = false;
  Map<String, dynamic> _linkedData = {};
  // ---------------------------------

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadLinkStatus(); // تحميل حالة الربط
    await _loadSavedFiles(); // تحميل الملفات
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadSavedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final filesJson = prefs.getStringList('saved_files') ?? [];
    if (mounted) {
      _savedFiles = filesJson
          .map((jsonString) => SavedFile.fromJson(jsonDecode(jsonString)))
          .toList();
      _savedFiles.sort((a, b) => b.date.compareTo(a.date));
    }
  }

  // --- ٤. دالة جديدة لتحميل بيانات الربط ---
  Future<void> _loadLinkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLinked = prefs.getBool('is_network_linked') ?? false;
    if (isLinked) {
      final dataString = prefs.getString('qahtani_linked_data');
      if (dataString != null && mounted) {
        setState(() {
          _isNetworkLinked = true;
          _linkedData = jsonDecode(dataString);
        });
      }
    }
  }
  // ---------------------------------------

  Future<void> _shareFile(String path) async {
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'فشلت عملية المشاركة.');
    }
  }

  Future<void> _deleteFile(SavedFile fileToDelete) async {
    try {
      final file = File(fileToDelete.path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // تجاهل الخطأ إذا فشل حذف الملف الفعلي
    }

    _savedFiles.remove(fileToDelete);
    final prefs = await SharedPreferences.getInstance();
    final updatedFilesJson =
        _savedFiles.map((file) => jsonEncode(file.toJson())).toList();
    await prefs.setStringList('saved_files', updatedFilesJson);
    setState(() {});
  }

  Future<void> _viewFile(String path) async {
    try {
      final file = File(path);
      final fileContent = await file.readAsString();
      // إزالة أي أسطر فارغة قد تنتج عن الانقسام
      final cardList = fileContent
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            // --- ٥. تمرير بيانات الربط للشاشة التالية ---
            builder: (context) => CardListScreen(
              cardList: cardList,
              isNetworkLinked: _isNetworkLinked,
              linkedData: _linkedData,
            ),
            // ----------------------------------------
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'فشل عرض الملف.');
    }
  }

  // --- ٦. دالة جديدة للمشاركة كملف PDF مع دعم التصميم الافتراضي والطباعة ---
  Future<void> _shareAsPdf(SavedFile savedFile) async {
    if (!mounted) return;
    showSuccessSnackBar(context, 'جاري تحضير ملف PDF...');

    try {
      // البحث عن القالب المطابق لاسم الفئة إن وجد
      final relevantTemplate =
          await PdfTemplateStorage.findForProfile(savedFile.profileName);

      // قراءة أسماء وبيانات المستخدمين من الملف النصي
      final file = File(savedFile.path);
      final fileContent = await file.readAsString();
      final cardLines = fileContent
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (cardLines.isEmpty) {
        if (!mounted) return;
        showErrorSnackBar(context, 'الملف فارغ ولا يحتوي على كروت.');
        return;
      }

      // استدعاء دالة إنشاء ومشاركة الـ PDF (تدعم التصميم الافتراضي إن لم يوجد قالب)
      if (!mounted) return;
      await PdfGenerator.sharePdf(
        context,
        cardUsernames: cardLines,
        template: relevantTemplate,
        profileName: savedFile.profileName,
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'فشل إنشاء ملف PDF: $e');
    }
  }

  Future<void> _printSavedFile(SavedFile savedFile) async {
    if (!mounted) return;
    showSuccessSnackBar(context, 'جاري فتح شاشة الطباعة...');

    try {
      final relevantTemplate =
          await PdfTemplateStorage.findForProfile(savedFile.profileName);

      final file = File(savedFile.path);
      final fileContent = await file.readAsString();
      final cardLines = fileContent
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (cardLines.isEmpty) {
        if (!mounted) return;
        showErrorSnackBar(context, 'الملف فارغ ولا يحتوي على كروت.');
        return;
      }

      if (!mounted) return;
      await PdfGenerator.printPdf(
        context,
        cards: cardLines,
        template: relevantTemplate,
        profileName: savedFile.profileName,
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'فشل فتح الطباعة: $e');
    }
  }

  // ----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملفات الكروت المحفوظة'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedFiles.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد ملفات محفوظة.',
                    style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).textTheme.titleMedium?.color ??
                            Theme.of(context).colorScheme.onSurface),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _savedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _savedFiles[index];
                    final formattedDate =
                        DateFormat('yyyy-MM-dd – hh:mm a').format(file.date);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.description,
                            color: Theme.of(context).appColors.info, size: 30),
                        title: Text('فئة: ${file.profileName}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'العدد: ${file.userCount} كرت\nالتاريخ: $formattedDate'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility,
                                  color: Theme.of(context).appColors.info),
                              onPressed: () => _viewFile(file.path),
                              tooltip: 'عرض',
                            ),
                            // --- ٧. زر الطباعة المباشر وزر المشاركة كـ PDF الجديد ---
                            IconButton(
                              icon: Icon(Icons.print_rounded,
                                  color: Theme.of(context).appColors.primary),
                              onPressed: () => _printSavedFile(file),
                              tooltip: 'طباعة كروت PDF',
                            ),
                            IconButton(
                              icon: Icon(Icons.picture_as_pdf,
                                  color: Theme.of(context).appColors.warning),
                              onPressed: () => _shareAsPdf(file),
                              tooltip: 'مشاركة كـ PDF',
                            ),
                            // ----------------------------------
                            IconButton(
                              icon: Icon(Icons.share,
                                  color: Theme.of(context).appColors.success),
                              onPressed: () => _shareFile(file.path),
                              tooltip: 'مشاركة كملف نصي',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Theme.of(context).appColors.error),
                              onPressed: () => _deleteFile(file),
                              tooltip: 'حذف',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
