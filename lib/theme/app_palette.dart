import 'package:flutter/material.dart';

// ============================================================
//  🎨 MikroTik Manager — Theme System v2 (Restructured)
//
//  Design Principles:
//  ─────────────────────────────────────────────────────
//  1. **Semantic Tokens** — لا ألوان خام (raw hex) في الكود.
//     كل لون له معنى وظيفي (surface, success, onError...).
//  2. **Layered surfaces** — 4 مستويات للسطوح:
//       background < surface < surfaceVariant < card
//     توفر عمقاً بصرياً بدون تباين صارخ.
//  3. **Token families** — كل عائلة لونية لها 3-5 درجات:
//       primary/secondary/accent → container + onContainer
//       success/warning/error/info → container + onContainer
//  4. **Text hierarchy** — 4 مستويات: primary/secondary/tertiary/disabled
//  5. **Outline system** — outline (strong) + outlineVariant (subtle)
//  6. **WCAG AA contrast** — كل الألوان المركّبة تتجاوز 4.5:1.
//  7. **Dark-first** — الثيم الداكن هو الأساسي، الفاتح هو المرآة.
//
//  Palette: Dark Navy + Teal (مريح للعين، عصري)
// ============================================================

abstract class AppPalette {
  // ============================================================
  //  Primary — Navy (اللون الأساسي للهوية)
  // ============================================================
  static const primary = Color(0xFF1A237E);          // Navy 900
  static const primaryLight = Color(0xFF3949AB);     // Indigo 700
  static const primaryDark = Color(0xFF0D1457);      // Navy أعمق
  static const primaryContainer = Color(0xFFE8EAF6); // Indigo 50 — light bg
  static const primaryContainerDark = Color(0xFF1A2540); // Navy container dark
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF0D1457);
  static const onPrimaryContainerDark = Color(0xFFE8EAF6);

  // ============================================================
  //  Secondary — Teal (لون التأكيد والتفاعل)
  // ============================================================
  static const secondary = Color(0xFF00897B);        // Teal 600
  static const secondaryLight = Color(0xFF26A69A);   // Teal 400
  static const secondaryDark = Color(0xFF004D40);    // Teal 800
  static const secondaryContainer = Color(0xFFB2DFDB); // Teal 100
  static const secondaryContainerDark = Color(0xFF003F36); // Teal 900
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF004D40);
  static const onSecondaryContainerDark = Color(0xFFB2DFDB);

  // ============================================================
  //  Accent — Deep Orange (للمميزات النادرة)
  // ============================================================
  static const accent = Color(0xFFFF7043);            // Deep Orange 400
  static const accentContainer = Color(0xFFFFCCBC);   // Deep Orange 100
  static const accentContainerDark = Color(0xFF5D2E1E);
  static const onAccent = Color(0xFFFFFFFF);
  static const onAccentContainer = Color(0xFF5D2E1E);
  static const onAccentContainerDark = Color(0xFFFFCCBC);

  // ============================================================
  //  Semantic Colors — ألوان الحالة (success/warning/error/info)
  //  كل عائلة لها: base + container + onContainer
  // ============================================================
  // Success
  static const success = Color(0xFF26A69A);          // Teal 400
  static const successContainer = Color(0xFFB2DFDB);
  static const successContainerDark = Color(0xFF003F36);
  static const onSuccess = Color(0xFFFFFFFF);
  static const onSuccessContainer = Color(0xFF004D40);
  static const onSuccessContainerDark = Color(0xFFB2DFDB);

  // Warning
  static const warning = Color(0xFFFFB74D);          // Amber 300
  static const warningContainer = Color(0xFFFFE0B2);
  static const warningContainerDark = Color(0xFF4A3500);
  static const onWarning = Color(0xFF1A1200);
  static const onWarningContainer = Color(0xFF4A3500);
  static const onWarningContainerDark = Color(0xFFFFE0B2);

  // Error
  static const error = Color(0xFFEF5350);            // Red 400
  static const errorContainer = Color(0xFFFFCDD2);
  static const errorContainerDark = Color(0xFF5D1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFF5D1A1A);
  static const onErrorContainerDark = Color(0xFFFFCDD2);

  // Info
  static const info = Color(0xFF4FC3F7);             // Light Blue 300
  static const infoContainer = Color(0xFFB3E5FC);
  static const infoContainerDark = Color(0xFF003C5A);
  static const onInfo = Color(0xFF00243A);
  static const onInfoContainer = Color(0xFF003C5A);
  static const onInfoContainerDark = Color(0xFFB3E5FC);

  // ============================================================
  //  Light Mode — Neutral Surfaces
  //  background < surface < surfaceVariant < card
  // ============================================================
  static const lightBackground = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF5F7FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardInteractive = Color(0xFFF0F3F8);
  static const lightCardHover = Color(0xFFEBEEF3);

  // ============================================================
  //  Dark Mode — Neutral Surfaces (متناسقة بدون تباين صارخ)
  //  background < surface < surfaceVariant < card < cardInteractive
  // ============================================================
  static const darkBackground = Color(0xFF0A0E27);       // Navy أعمق مستوى
  static const darkSurface = Color(0xFF12182E);           // Navy بطاقة عادية
  static const darkSurfaceVariant = Color(0xFF1A2540);    // Navy بطاقة تفاعلية
  static const darkCard = Color(0xFF12182E);              // نفس السطح (متوافق)
  static const darkCardInteractive = Color(0xFF1A2540);   // Navy أفتح
  static const darkCardHover = Color(0xFF243050);         // Navy أفتح للـ hover
  static const darkCardSecondary = Color(0xFF1A2540);     // alias للتوافق القديم

  // ============================================================
  //  Outline (borders) — ناعم متناسق
  // ============================================================
  static const lightOutline = Color(0xFFCFD8DC);          // Blue Grey 200
  static const lightOutlineVariant = Color(0xFFE0E5EB);   // Blue Grey 100
  static const darkOutline = Color(0xFF2A3654);           // Navy outline
  static const darkOutlineVariant = Color(0xFF1F2942);    // Navy outline subtle

  // ============================================================
  //  Text Hierarchy — 4 مستويات
  // ============================================================
  // Light
  static const lightTextPrimary = Color(0xFF0A0E27);      // Navy 900 — أغمق
  static const lightTextSecondary = Color(0xFF455A64);    // Blue Grey 600
  static const lightTextTertiary = Color(0xFF78909C);     // Blue Grey 400
  static const lightTextDisabled = Color(0xFFB0BEC5);     // Blue Grey 200

  // Dark — كلها فاتحة على الخلفية الداكنة (WCAG AA)
  static const darkTextPrimary = Color(0xFFECEFF1);       // Grey 50 — أبيض ناعم
  static const darkTextSecondary = Color(0xFFB0BEC5);     // Blue Grey 200
  static const darkTextTertiary = Color(0xFF78909C);      // Blue Grey 400
  static const darkTextDisabled = Color(0xFF4A5568);      // أغمق للنص المعطّل

  // ============================================================
  //  تدرّجات
  // ============================================================
  static const gradientStart = primary;
  static const gradientEnd = secondary;

  static const gradientSoftStart = lightBackground;
  static const gradientSoftMiddle = lightSurfaceVariant;
  static const gradientSoftEnd = primaryContainer;

  static const gradientDarkStart = darkBackground;
  static const gradientDarkEnd = darkSurfaceVariant;

  static const signStartGradient = primary;
  static const signEndGradient = primaryDark;

  static const drawerHeader = primary;

  // ============================================================
  //  Social Media
  // ============================================================
  static const socialFacebook = Color(0xFF1877F2);
  static const socialTwitter = Color(0xFF1DA1F2);
  static const socialDribbble = Color(0xFFEA4C89);

  // ============================================================
  //  Deprecated — للتوافق مع الكود القديم (يجب استبدالها تدريجياً)
  // ============================================================
  @Deprecated('استخدم lightBackground / darkBackground')
  static const bgColorScreen = lightBackground;
  @Deprecated('استخدم lightCard / darkCard')
  static const cardSurface = lightCard;
  @Deprecated('استخدم lightSurfaceVariant')
  static const priceColor = lightSurfaceVariant;
  @Deprecated('استخدم lightOutline')
  static const defaultColor = lightOutline;
  static const muted = Color(0xFF90A4AE);
  static const input = lightSurfaceVariant;
  static const active = primary;
  static const placeholder = muted;
  static const switchOff = lightOutline;
  static const border = lightOutline;
  static const caption = lightTextSecondary;

  // أسماء نصوص قديمة
  @Deprecated('استخدم lightTextPrimary / darkTextPrimary')
  static const textPrimary = lightTextPrimary;
  @Deprecated('استخدم lightTextSecondary / darkTextSecondary')
  static const textSecondary = lightTextSecondary;
  static const textWhite = Color(0xFFFFFFFF);
  @Deprecated('استخدم lightTextTertiary / darkTextTertiary')
  static const textMuted = muted;
  static const textOnDarkCard = darkTextPrimary;
  static const textSecondaryOnDark = darkTextSecondary;
  static const textSecondaryOnCard = darkTextSecondary;
}
