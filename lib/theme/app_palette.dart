import 'package:flutter/material.dart';

/// 🎨 ثيم MikroTik Manager — Dark Navy + Teal
/// متناسق بالكامل، مريح للعين، عصري
abstract class AppPalette {
  // ============================================================
  //  الألوان الأساسية — Navy (Primary)
  // ============================================================
  static const primary = Color(0xFF1A237E);         // Navy 900 — أساسي
  static const primaryLight = Color(0xFF3949AB);    // Indigo 700
  static const primaryDark = Color(0xFF0D1457);     // Navy أغمق

  // ============================================================
  //  الألوان الثانوية — Teal
  // ============================================================
  static const secondary = Color(0xFF00897B);       // Teal 600
  static const secondaryLight = Color(0xFF26A69A);  // Teal 400
  static const secondaryDark = Color(0xFF004D40);   // Teal 800

  static const accent = Color(0xFFFF7043);           // Deep Orange 400

  // ============================================================
  //  ألوان الحالة
  // ============================================================
  static const success = Color(0xFF26A69A);
  static const warning = Color(0xFFFFB74D);
  static const error = Color(0xFFEF5350);
  static const info = Color(0xFF4FC3F7);

  // ============================================================
  //  الألوان المحايدة — الفاتح
  // ============================================================
  static const defaultColor = Color(0xFFCFD8DC);
  static const muted = Color(0xFF90A4AE);
  static const input = Color(0xFFECEFF1);
  static const active = Color(0xFF1A237E);
  static const placeholder = Color(0xFF90A4AE);
  static const switchOff = Color(0xFFCFD8DC);
  static const border = Color(0xFFCFD8DC);
  static const caption = Color(0xFF546E7A);

  // ============================================================
  //  الخلفيات — الفاتح
  // ============================================================
  static const bgColorScreen = Color(0xFFFAFAFA);
  static const cardSurface = Color(0xFFFFFFFF);
  static const priceColor = Color(0xFFE8EAF6);

  // ============================================================
  //  التدرجات
  // ============================================================
  static const gradientStart = Color(0xFF1A237E);
  static const gradientEnd = Color(0xFF00897B);

  static const gradientSoftStart = Color(0xFFFAFAFA);
  static const gradientSoftMiddle = Color(0xFFF3F4F6);
  static const gradientSoftEnd = Color(0xFFE8EAF6);

  static const signStartGradient = Color(0xFF1A237E);
  static const signEndGradient = Color(0xFF0D1457);

  static const drawerHeader = Color(0xFF1A237E);

  static const socialFacebook = Color(0xFF1877F2);
  static const socialTwitter = Color(0xFF1DA1F2);
  static const socialDribbble = Color(0xFFEA4C89);

  // ============================================================
  //  الثيم الداكن — Dark Navy متناسق
  //  خلفية < بطاقة < بطاقة تفاعلية (تدرج 3 مستويات)
  // ============================================================
  static const darkBackground = Color(0xFF0A0E27);       // Navy أعمق مستوى
  static const darkSurface = Color(0xFF12182E);           // Navy بطاقة
  static const darkCard = Color(0xFF12182E);              // نفس السطح
  static const darkCardSecondary = Color(0xFF1A2540);     // Navy بطاقة تفاعلية
  static const darkCardInteractive = Color(0xFF243050);   // Navy أفتح

  // ============================================================
  //  ألوان النصوص — متناسقة
  // ============================================================
  static const textPrimary = Color(0xFF0A0E27);
  static const textSecondary = Color(0xFF546E7A);
  static const textWhite = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF90A4AE);

  // نصوص الثيم الداكن — كلها فاتحة على الخلفية الداكنة
  static const textOnDarkCard = Color(0xFFECEFF1);       // أبيض ناعم
  static const textSecondaryOnDark = Color(0xFF90A4AE);   // رمادي أزرق
  static const textSecondaryOnCard = Color(0xFFB0BEC5);   // رمادي أفتح
}
