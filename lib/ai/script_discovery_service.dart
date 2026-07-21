// ============================================================
//  ScriptDiscoveryService — اكتشاف سكربتات MikroTik
//
//  مستوحى من MKT_flutter_scripts/lib/services/script_service.dart
//  - يكتشف السكربتات الموجودة على الجهاز عبر RouterOS API
//  - يستخرج الـ comments كأوصاف للسكربتات
//  - يدعم JSON caching محلياً لكل جهاز
//  - يدعم user level access control (mkt1_, mkt2_ naming)
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../mikrotik_connector.dart';

/// يمثل سكربت MikroTik مع وصفه
class MikrotikScript {
  final String name;
  final String? comment;
  final int? userLevel; // من prefix mkt<N>_

  const MikrotikScript({
    required this.name,
    this.comment,
    this.userLevel,
  });

  /// هل يتبع اصطلاح mkt<N>_ ؟
  bool get hasLevelPrefix => name.startsWith(RegExp(r'mkt\d+_'));
}

class ScriptDiscoveryService {
  ScriptDiscoveryService._();

  /// يكتشف كل السكربتات على الجهاز
  ///
  /// استراتيجية (مستوحاة من MKT_flutter_scripts):
  /// 1. `/system/script/print` للحصول على كل السكربتات
  /// 2. استخراج الـ name و الـ comment من كل سكربت
  /// 3. فلترة حسب user level (إن طُلب)
  /// 4. حفظ النتائج في cache محلي
  static Future<List<MikrotikScript>> discoverScripts({
    int? userLevel,
    bool useCache = true,
  }) async {
    // محاولة قراءة من cache أولاً
    if (useCache) {
      final cached = await _loadFromCache();
      if (cached != null) {
        debugPrint('[ScriptDiscovery] Loaded ${cached.length} scripts from cache');
        return _filterByLevel(cached, userLevel);
      }
    }

    // قراءة من الجهاز
    try {
      final client = await MikrotikConnector.connect();
      final response = await client.talk([
        '/system/script/print',
        '=.proplist=name,comment,source',
      ]);

      final scripts = <MikrotikScript>[];
      for (final item in response) {
        final name = item['name'] ?? '';
        if (name.isEmpty) continue;

        final comment = item['comment'];
        final level = _extractLevel(name);

        scripts.add(MikrotikScript(
          name: name,
          comment: comment,
          userLevel: level,
        ));
      }

      debugPrint('[ScriptDiscovery] Discovered ${scripts.length} scripts');

      // حفظ في cache
      await _saveToCache(scripts);

      return _filterByLevel(scripts, userLevel);
    } catch (e) {
      debugPrint('[ScriptDiscovery] Error: $e');
      rethrow;
    }
  }

  /// ينفذ سكربت MikroTik عبر `/system script run`
  static Future<String> runScript(String scriptName) async {
    final client = await MikrotikConnector.connect();
    final response = await client.talk([
      '/system/script/run',
      '=.id=$scriptName',
    ]);

    final buffer = StringBuffer();
    for (final item in response) {
      item.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
    }
    return buffer.toString().trim();
  }

  /// يستخرج user level من اسم السكربت
  /// مثال: `mkt1_backup` → 1، `mkt2_config` → 2، `backup` → null
  static int? _extractLevel(String name) {
    final match = RegExp(r'^mkt(\d+)_').firstMatch(name);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// يفلتر السكربتات حسب user level
  /// Level 1: يمكنه الوصول لـ mkt1_ و mkt2_
  /// Level 2: يمكنه الوصول لـ mkt2_ فقط
  static List<MikrotikScript> _filterByLevel(
      List<MikrotikScript> scripts, int? userLevel) {
    if (userLevel == null) return scripts;

    return scripts.where((script) {
      if (script.userLevel == null) return false; // لا يتبع الاصطلاح
      if (userLevel == 1) {
        return script.userLevel == 1 || script.userLevel == 2;
      }
      return script.userLevel == userLevel;
    }).toList();
  }

  // ============================================================
  //  JSON Caching — مستوحى من MKT_flutter_scripts
  // ============================================================

  static Future<String?> get _cachePath async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/script_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final ip = MikrotikConnector.currentIp ?? 'unknown';
    return '${cacheDir.path}/scripts_${ip.replaceAll('.', '_')}.json';
  }

  static Future<List<MikrotikScript>?> _loadFromCache() async {
    try {
      final path = await _cachePath;
      final file = File(path!);
      if (!await file.exists()) return null;

      final json = jsonDecode(await file.readAsString()) as List;
      final scripts = json.map((item) {
        final map = item as Map<String, dynamic>;
        return MikrotikScript(
          name: map['name'] as String,
          comment: map['comment'] as String?,
          userLevel: map['userLevel'] as int?,
        );
      }).toList();

      return scripts;
    } catch (e) {
      debugPrint('[ScriptDiscovery] Cache load error: $e');
      return null;
    }
  }

  static Future<void> _saveToCache(List<MikrotikScript> scripts) async {
    try {
      final path = await _cachePath;
      final json = jsonEncode(scripts.map((s) => {
            'name': s.name,
            'comment': s.comment,
            'userLevel': s.userLevel,
          }).toList());
      await File(path!).writeAsString(json);
      debugPrint('[ScriptDiscovery] Saved ${scripts.length} scripts to cache');
    } catch (e) {
      debugPrint('[ScriptDiscovery] Cache save error: $e');
    }
  }

  /// يحذف الـ cache (يُستخدم عند تغيير السكربتات)
  static Future<void> clearCache() async {
    try {
      final path = await _cachePath;
      final file = File(path!);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[ScriptDiscovery] Cache cleared');
      }
    } catch (_) {}
  }
}
