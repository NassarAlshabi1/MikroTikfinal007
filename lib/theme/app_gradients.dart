import 'package:flutter/material.dart';
import 'app_palette.dart';

/// 🎨 التدرجات اللونية الحديثة الأنيقة
/// تصميم 2025: تدرجات ناعمة هادئة، غير صارخة
abstract class AppGradients {
  /// خلفية ناعمة للثيم الفاتح — تدرج هادئ جداً من الأبيض المائل للأزرق
  static const LinearGradient softBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppPalette.gradientSoftStart,   // Slate 50
      AppPalette.gradientSoftMiddle,  // Blue 50
      AppPalette.gradientSoftEnd,     // Violet 50
    ],
  );

  /// تدرج البطاقات في الثيم الفاتح — أبيض شفاف ناعم
  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAFBFF),
    ],
  );

  /// خلفية الثيم الداكن — تدرج عميق أنيق
  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),  // Slate 950
      Color(0xFF1E293B),  // Slate 800
      Color(0xFF312E81),  // Indigo 900 (لمسة لونية خفيفة)
    ],
    stops: [0.0, 0.6, 1.0],
  );

  /// تدرج البطاقات البيضاء على الثيم الداكن — تأثير الزجاج (Glassmorphism)
  static const LinearGradient lightCardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAFBFC),
    ],
  );

  /// تدرج البطاقات المرتفعة في الثيم الداكن
  static const LinearGradient darkCardElevation = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
      Color(0xFFF1F5F9),
    ],
  );

  /// تدرج ناعم للـ overlays الداكنة
  static const LinearGradient softDarkOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xE60F172A),  // Slate 950 at 90%
      Color(0xF01E293B),  // Slate 800 at 94%
    ],
  );

  /// تدرج الـ AppBar الرئيسي — Indigo إلى Violet
  static const LinearGradient primaryAppBar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppPalette.gradientStart,
      AppPalette.gradientEnd,
    ],
  );

  /// تدرج أزرار الـ Sign In — عميق أنيق
  static const LinearGradient signInButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppPalette.signStartGradient,
      AppPalette.gradientEnd,
    ],
  );

  /// تدرج ناعم للـ FAB (Floating Action Button)
  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppPalette.primary,
      AppPalette.secondary,
    ],
  );
}
