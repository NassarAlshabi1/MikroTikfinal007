import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pdf_template.dart';

class PdfTemplateStorage {
  PdfTemplateStorage._();

  static const String storageKey = 'pdf_templates';
  static Future<void> _writeChain = Future<void>.value();

  static Future<List<PdfTemplate>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTemplates = prefs.getStringList(storageKey) ?? <String>[];
    final validRaw = <String>[];
    final templates = <PdfTemplate>[];

    for (final raw in rawTemplates) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final template = PdfTemplate.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        templates.add(template);
        validRaw.add(jsonEncode(template.toJson()));
      } catch (_) {
        // حذف السجل التالف من النسخة المصححة أدناه بدلاً من تعطيل الشاشة.
      }
    }

    if (validRaw.length != rawTemplates.length) {
      await _enqueueWrite(() => prefs.setStringList(storageKey, validRaw));
    }
    return templates;
  }

  static Future<PdfTemplate?> findForProfile(String profileName) async {
    final normalized = profileName.trim();
    if (normalized.isEmpty) return null;
    final templates = await load();
    for (final template in templates.reversed) {
      if (template.profileName == normalized &&
          await File(template.imagePath).exists()) {
        return template;
      }
    }
    return null;
  }

  static Future<void> save(PdfTemplate template) async {
    template.validate();
    final prefs = await SharedPreferences.getInstance();
    await _enqueueWrite(() async {
      final templates = await _loadWithoutRepair(prefs);
      templates.removeWhere(
        (existing) =>
            existing.id == template.id ||
            existing.profileName == template.profileName,
      );
      templates.add(template);
      await prefs.setStringList(
        storageKey,
        templates.map((item) => jsonEncode(item.toJson())).toList(),
      );
    });
  }

  static Future<void> delete(PdfTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    await _enqueueWrite(() async {
      final templates = await _loadWithoutRepair(prefs);
      templates.removeWhere(
        (existing) =>
            existing.id == template.id ||
            existing.profileName == template.profileName,
      );
      await prefs.setStringList(
        storageKey,
        templates.map((item) => jsonEncode(item.toJson())).toList(),
      );
    });

    try {
      final image = File(template.imagePath);
      if (await image.exists()) await image.delete();
    } catch (_) {
      // حذف سجل القالب أهم من فشل حذف صورة قديمة.
    }
  }

  static Future<List<PdfTemplate>> _loadWithoutRepair(
    SharedPreferences prefs,
  ) async {
    final rawTemplates = prefs.getStringList(storageKey) ?? <String>[];
    final templates = <PdfTemplate>[];
    for (final raw in rawTemplates) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          templates.add(
            PdfTemplate.fromJson(Map<String, dynamic>.from(decoded)),
          );
        }
      } catch (_) {
        // تجاهل السجل التالف عند إعادة بناء القائمة.
      }
    }
    return templates;
  }

  static Future<T> _enqueueWrite<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _writeChain = _writeChain.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}
