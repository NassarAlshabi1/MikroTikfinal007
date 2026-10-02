import 'package:flutter/material.dart';

/// وصف ميزة واحدة من ميزات إشعارات Telegram.
class TelegramFeature {
  /// المعرّف الثابت (يُستخدم في التخزين — لا يُغيَّر بعد الإصدار).
  final String id;

  /// العنوان المعروض.
  final String title;

  /// الشرح المختصر.
  final String subtitle;

  /// شارة الفترة: فوري · دوري · يومي · تنبيه.
  final String badge;

  final IconData icon;
  final Color color;

  const TelegramFeature({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
  });
}

/// كتالوج ميزات Telegram + قواعد تفعيلها (منطق نقي قابل للاختبار).
class TelegramFeatureCatalog {
  const TelegramFeatureCatalog._();

  static const List<TelegramFeature> all = [
    TelegramFeature(
      id: 'netwatch',
      title: 'انقطاع أجهزة البث (Netwatch)',
      subtitle: 'إشعار فوري عند انقطاع أو عودة أي جهاز بث عن الشبكة بشكل منفصل',
      badge: 'فوري',
      icon: Icons.wifi_tethering_error_rounded,
      color: Color(0xFF38BDF8),
    ),
    TelegramFeature(
      id: 'devices_status',
      title: 'حالة أجهزة البث الدورية',
      subtitle: 'تقرير دوري بعدد أجهزة البث المتصلة وحالتها',
      badge: 'دوري',
      icon: Icons.devices_other_rounded,
      color: Color(0xFF22C55E),
    ),
    TelegramFeature(
      id: 'router_status',
      title: 'حالة الراوتر',
      subtitle: 'المعالج والذاكرة ومدة التشغيل وإصدار RouterOS',
      badge: 'دوري',
      icon: Icons.router_rounded,
      color: Color(0xFF3B82F6),
    ),
    TelegramFeature(
      id: 'sales',
      title: 'تقرير المبيعات',
      subtitle: 'مبيعات اليوم: عدد الكروت وإجمالي المبلغ',
      badge: 'دوري',
      icon: Icons.point_of_sale_rounded,
      color: Color(0xFFF59E0B),
    ),
    TelegramFeature(
      id: 'active_users',
      title: 'المتصلون الآن',
      subtitle: 'عدد المستخدمين النشطين في كل تقرير',
      badge: 'دوري',
      icon: Icons.people_alt_rounded,
      color: Color(0xFF8B5CF6),
    ),
    TelegramFeature(
      id: 'disk_alert',
      title: 'تنبيه مساحة التخزين',
      subtitle: 'تحذير عند انخفاض المساحة الحرة عن الحد الآمن',
      badge: 'تنبيه',
      icon: Icons.sd_storage_rounded,
      color: Color(0xFFEF4444),
    ),
    TelegramFeature(
      id: 'daily_summary',
      title: 'ملخص يومي شامل',
      subtitle: 'رسالة واحدة في نهاية اليوم تجمع كل ما سبق',
      badge: 'يومي',
      icon: Icons.summarize_rounded,
      color: Color(0xFF14B8A6),
    ),
  ];

  /// البحث عن ميزة بمعرّفها.
  static TelegramFeature? byId(String id) {
    for (final feature in all) {
      if (feature.id == id) return feature;
    }
    return null;
  }

  /// المعرّفات المعروفة فقط (غير المفهوم يُستبعد بلا تخمين).
  static List<String> get ids => all.map((f) => f.id).toList();

  /// خريطة افتراضية: كل الميزات مفعّلة.
  static Map<String, bool> defaultFlags({bool enabled = true}) {
    return {for (final f in all) f.id: enabled};
  }

  /// تنقية خريطة قادمة من التخزين: المعرّفات غير المعروفة تُحذف،
  /// والناقص يُضاف بالقيمة الافتراضية.
  static Map<String, bool> normalize(
    Map<String, dynamic>? raw, {
    bool fallback = true,
  }) {
    final result = <String, bool>{};
    for (final feature in all) {
      final value = raw?[feature.id];
      if (value is bool) {
        result[feature.id] = value;
      } else if (value is String) {
        result[feature.id] = value == '1' || value.toLowerCase() == 'true';
      } else {
        result[feature.id] = fallback;
      }
    }
    return result;
  }

  /// كم ميزة مفعّلة؟
  static int enabledCount(Map<String, bool> flags) {
    return all.where((f) => flags[f.id] == true).length;
  }

  /// تفعيل/تعطيل الكل.
  static Map<String, bool> setAll(Map<String, bool> flags, bool value) {
    return {for (final f in all) f.id: value};
  }

  /// تبديل ميزة واحدة.
  static Map<String, bool> toggle(Map<String, bool> flags, String id) {
    final result = Map<String, bool>.from(flags);
    result[id] = !(result[id] ?? false);
    return result;
  }

  /// هل الميزة مفعّلة؟
  static bool isEnabled(Map<String, bool> flags, String id) =>
      flags[id] == true;
}
