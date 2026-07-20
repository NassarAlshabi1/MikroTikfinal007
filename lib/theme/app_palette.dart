import 'package:flutter/material.dart';

/// 🎨 ثيم MikroTik Manager الحديث الأنيق — Material 3
/// مستوحى من تصاميم 2024-2025: Apple Liquid Glass + Material You
/// ألوان هادئة احترافية مع تباين عالي للوضوح
abstract class AppPalette {
  // ============================================================
  //  الألوان الأساسية — Primary (Indigo حديث)
  // ============================================================
  static const primary = Color(0xFF4F46E5);       // Indigo 600
  static const primaryLight = Color(0xFF818CF8);  // Indigo 400
  static const primaryDark = Color(0xFF3730A3);  // Indigo 800

  // ============================================================
  //  الألوان الثانوية — Secondary (Teal)
  // ============================================================
  static const secondary = Color(0xFF14B8A6);    // Teal 500
  static const secondaryLight = Color(0xFF5EEAD4); // Teal 300
  static const secondaryDark = Color(0xFF0F766E);  // Teal 700

  // ============================================================
  //  ألوان التمييز — Accent (Amber for highlights)
  // ============================================================
  static const accent = Color(0xFFF59E0B);        // Amber 500

  // ============================================================
  //  ألوان الحالة — Status Colors (Tailwind-inspired)
  // ============================================================
  static const success = Color(0xFF10B981);       // Emerald 500
  static const warning = Color(0xFFF59E0B);       // Amber 500
  static const error = Color(0xFFEF4444);         // Red 500
  static const info = Color(0xFF3B82F6);          // Blue 500

  // ============================================================
  //  الألوان المحايدة — Neutral (Slate)
  // ============================================================
  static const defaultColor = Color(0xFFCBD5E1);   // Slate 300
  static const muted = Color(0xFF94A3B8);         // Slate 400
  static const input = Color(0xFFF1F5F9);         // Slate 100
  static const active = Color(0xFF4F46E5);
  static const placeholder = Color(0xFF94A3B8);
  static const switchOff = Color(0xFFCBD5E1);
  static const border = Color(0xFFE2E8F0);        // Slate 200
  static const caption = Color(0xFF475569);       // Slate 600

  // ============================================================
  //  ألوان الخلفية — Backgrounds
  // ============================================================
  static const bgColorScreen = Color(0xFFF8FAFC);  // Slate 50
  static const cardSurface = Color(0xFFFFFFFF);
  static const priceColor = Color(0xFFE0E7FF);     // Indigo 100

  // ============================================================
  //  التدرجات اللونية — Gradients
  // ============================================================
  static const gradientStart = Color(0xFF4F46E5);
  static const gradientEnd = Color(0xFF7C3AED);  // Violet 600

  static const gradientSoftStart = Color(0xFFF8FAFC);
  static const gradientSoftMiddle = Color(0xFFEFF6FF);  // Blue 50
  static const gradientSoftEnd = Color(0xFFFAF5FF);    // Violet 50

  // Sign/Auth Gradient (Login screen)
  static const signStartGradient = Color(0xFF4F46E5);
  static const signEndGradient = Color(0xFF1E1B4B);  // Indigo 950

  // ============================================================
  //  الـ Drawer
  // ============================================================
  static const drawerHeader = Color(0xFF312E81);  // Indigo 900

  // ============================================================
  //  ألوان إضافية للوضوح
  // ============================================================
  static const socialFacebook = Color(0xFF1877F2);
  static const socialTwitter = Color(0xFF1DA1F2);
  static const socialDribbble = Color(0xFFEA4C89);

  // ============================================================
  //  ألوان الثيم الداكن — Dark Theme
  //  تصميم حديث: خلفية داكنة عميقة + بطاقات بيضاء ناعمة
  // ============================================================
  static const darkBackground = Color(0xFF0F172A);        // Slate 950
  static const darkSurface = Color(0xFF1E293B);           // Slate 800
  static const darkCard = Color(0xFFFFFFFF);              // بطاقات بيضاء ناصعة
  static const darkCardSecondary = Color(0xFFF8FAFC);     // Slate 50
  static const darkCardInteractive = Color(0xFFF1F5F9);   // Slate 100

  // ============================================================
  //  ألوان النصوص — Text Colors
  // ============================================================
  static const textPrimary = Color(0xFF0F172A);           // Slate 950
  static const textSecondary = Color(0xFF475569);         // Slate 600
  static const textWhite = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF94A3B8);             // Slate 400

  // ألوان نصوص الثيم الداكن
  static const textOnDarkCard = Color(0xFF0F172A);        // نص غامق على البطاقات البيضاء
  static const textSecondaryOnDark = Color(0xFFCBD5E1);   // Slate 300
  static const textSecondaryOnCard = Color(0xFF64748B);   // Slate 500
}
