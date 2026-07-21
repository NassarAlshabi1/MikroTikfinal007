import 'package:flutter/material.dart';

/// 🎨 ثيم MikroTik Manager — متناسق بالكامل
/// مبدأ: نفس الألوان للنصوص، البطاقات، الخلفيات، العناوين في كل شاشة
/// لا تباين صارخ — تدرج لوني ناعم مريح للعين
abstract class AppPalette {
  // ============================================================
  //  الألوان الأساسية
  // ============================================================
  static const primary = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF3730A3);

  // ============================================================
  //  الألوان الثانوية
  // ============================================================
  static const secondary = Color(0xFF14B8A6);
  static const secondaryLight = Color(0xFF5EEAD4);
  static const secondaryDark = Color(0xFF0F766E);

  static const accent = Color(0xFFF59E0B);

  // ============================================================
  //  ألوان الحالة
  // ============================================================
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ============================================================
  //  الألوان المحايدة — الفاتح
  // ============================================================
  static const defaultColor = Color(0xFFCBD5E1);
  static const muted = Color(0xFF94A3B8);
  static const input = Color(0xFFF1F5F9);
  static const active = Color(0xFF4F46E5);
  static const placeholder = Color(0xFF94A3B8);
  static const switchOff = Color(0xFFCBD5E1);
  static const border = Color(0xFFE2E8F0);
  static const caption = Color(0xFF475569);

  // ============================================================
  //  الخلفيات — الفاتح
  // ============================================================
  static const bgColorScreen = Color(0xFFF8FAFC);
  static const cardSurface = Color(0xFFFFFFFF);
  static const priceColor = Color(0xFFE0E7FF);

  // ============================================================
  //  التدرجات
  // ============================================================
  static const gradientStart = Color(0xFF4F46E5);
  static const gradientEnd = Color(0xFF7C3AED);

  static const gradientSoftStart = Color(0xFFF8FAFC);
  static const gradientSoftMiddle = Color(0xFFEFF6FF);
  static const gradientSoftEnd = Color(0xFFFAF5FF);

  static const signStartGradient = Color(0xFF4F46E5);
  static const signEndGradient = Color(0xFF1E1B4B);

  static const drawerHeader = Color(0xFF312E81);

  static const socialFacebook = Color(0xFF1877F2);
  static const socialTwitter = Color(0xFF1DA1F2);
  static const socialDribbble = Color(0xFFEA4C89);

  // ============================================================
  //  الثيم الداكن — متناسق بالكامل
  //  مبدأ: خلفية < بطاقة < بطاقة تفاعلية (تدرج 3 مستويات)
  //  النص دائماً أبيض/رمادي فاتح على البطاقات الداكنة
  // ============================================================
  static const darkBackground = Color(0xFF0F172A);       // Slate 950 — أغمق مستوى
  static const darkSurface = Color(0xFF1E293B);           // Slate 800 — البطاقات
  static const darkCard = Color(0xFF1E293B);              // نفس السطح — متناسق
  static const darkCardSecondary = Color(0xFF334155);      // Slate 700 — بطاقة تفاعلية
  static const darkCardInteractive = Color(0xFF475569);   // Slate 600 — أفتح

  // ============================================================
  //  ألوان النصوص — متناسقة
  // ============================================================
  static const textPrimary = Color(0xFF0F172A);           // نص رئيسي فاتح
  static const textSecondary = Color(0xFF475569);         // نص ثانوي فاتح
  static const textWhite = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF94A3B8);             // نص خافت فاتح

  // نصوص الثيم الداكن — كلها فاتحة على الخلفية الداكنة
  static const textOnDarkCard = Color(0xFFF1F5F9);        // أبيض ناعم
  static const textSecondaryOnDark = Color(0xFF94A3B8);    // رمادي فاتح
  static const textSecondaryOnCard = Color(0xFFCBD5E1);    // رمادي أفتح
}
