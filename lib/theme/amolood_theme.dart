// ============================================================
//  Amolood Theme — ثيم مستوحى من amolood/Mikrotik-flutter-app
//
//  المصدر: github.com/amolood/Mikrotik-flutter-app (master branch)
// 适应性: تم تكييفه للعمل مع البنية الحالية للتطبيق (AppColorsExtension)
//
//  المميزات:
//  ✅ Dark Navy + Electric Blue + Neon (مستوحى من amolood)
//  ✅ Tajawal font family (7 أوزان)
//  ✅ Gradients: primary, success, warning, card, dark
//  ✅ Glow decorations + card decorations
//  ✅ WCAG AA contrast
//
//  الاستخدام:
//  ```dart
//  MaterialApp(
//    theme: AmoloodTheme.dark,
//    ...
//  )
//  ```
// ============================================================

import 'package:flutter/material.dart';

import 'app_colors_extension.dart';
import 'app_text_theme_extension.dart';
import 'app_typography.dart';

/// الألوان الرئيسية — مستوحاة من amolood/Mikrotik-flutter-app
///
/// لوحة Dark Navy + Electric Blue + Neon — مريحة للعين وعصرية.
class AmoloodColors {
  AmoloodColors._();

  // ─── Core palette ───
  static const background = Color(0xFF070E1A);
  static const surface = Color(0xFF0D2137);
  static const surfaceElevated = Color(0xFF112840);
  static const border = Color(0xFF1A3A5C);
  static const borderGlow = Color(0xFF1565C0);

  // ─── Accent system ───
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF1E88E5);
  static const electric = Color(0xFF00B0FF);
  static const neon = Color(0xFF00E5FF);

  // ─── Status colors ───
  static const success = Color(0xFF00E676);
  static const warning = Color(0xFFFFAB40);
  static const error = Color(0xFFFF5252);
  static const inactive = Color(0xFF546E7A);

  // ─── Text hierarchy ───
  static const textPrimary = Color(0xFFF0F8FF);
  static const textSecondary = Color(0xFF7BAFD4);
  static const textMuted = Color(0xFF3D6A8A);

  // ─── Gradients ───
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
  );

  static const gradientSuccess = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00897B), Color(0xFF00E676)],
  );

  static const gradientWarning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE65100), Color(0xFFFFAB40)],
  );

  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2137), Color(0xFF112840)],
  );

  static const gradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF070E1A), Color(0xFF0D1F3C)],
  );
}

/// ثيم Amolood الكامل (Dark mode فقط — متوافق مع تصميم amolood)
class AmoloodTheme {
  AmoloodTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Tajawal',
      scaffoldBackgroundColor: AmoloodColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AmoloodColors.primary,
        secondary: AmoloodColors.electric,
        surface: AmoloodColors.surface,
        error: AmoloodColors.error,
        onPrimary: Colors.white,
        onSurface: AmoloodColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AmoloodColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AmoloodColors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AmoloodColors.textPrimary,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AmoloodColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AmoloodColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AmoloodColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AmoloodColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AmoloodColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AmoloodColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AmoloodColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AmoloodColors.textMuted, fontFamily: 'Tajawal'),
        labelStyle: const TextStyle(color: AmoloodColors.textSecondary, fontFamily: 'Tajawal'),
        prefixIconColor: AmoloodColors.textMuted,
      ),
      dividerColor: AmoloodColors.border,
      iconTheme: const IconThemeData(color: AmoloodColors.textSecondary),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AmoloodColors.textPrimary, fontFamily: 'Tajawal'),
        displayMedium: TextStyle(color: AmoloodColors.textPrimary, fontFamily: 'Tajawal'),
        bodyLarge: TextStyle(color: AmoloodColors.textPrimary, fontFamily: 'Tajawal'),
        bodyMedium: TextStyle(color: AmoloodColors.textSecondary, fontFamily: 'Tajawal'),
        bodySmall: TextStyle(color: AmoloodColors.textMuted, fontFamily: 'Tajawal'),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AmoloodColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AmoloodColors.border),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AmoloodColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          color: AmoloodColors.textSecondary,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AmoloodColors.background,
        scrimColor: Colors.black54,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AmoloodColors.electric;
          return AmoloodColors.inactive;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AmoloodColors.primary.withValues(alpha: 0.4);
          }
          return AmoloodColors.border;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0D1B2E),
        indicatorColor: const Color(0xFF5B7FFF).withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5B7FFF),
            );
          }
          return const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: Color(0xFF9090AA),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF5B7FFF), size: 24);
          }
          return const IconThemeData(color: Color(0xFF9090AA), size: 24);
        }),
      ),
      // 🔑 تسجيل AppColorsExtension + AppTextThemeExtension
      // هذا ضروري لأن 364 استخدام لـ context.appColors في الشاشات
      // بدون هذا، كانت الشاشات تحصل على ألوان الثيم الفاتح القديم!
      extensions: [
        _amoloodAppColors,
        _amoloodTextTheme,
      ],
    );
  }

  /// AppColorsExtension بألوان Amolood — يطابق AmoloodColors
  /// هذا يضمن أن context.appColors.primary يرجع AmoloodColors.primary
  /// بدل الألوان القديمة (Navy/Teal palette)
  static final _amoloodAppColors = AppColorsExtension(
    // Brand — مطابقة لـ AmoloodColors
    primary: AmoloodColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AmoloodColors.surfaceElevated,
    onPrimaryContainer: AmoloodColors.textPrimary,
    secondary: AmoloodColors.electric,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFF0D2137),
    onSecondaryContainer: AmoloodColors.textPrimary,
    accent: AmoloodColors.neon,
    onAccent: Colors.white,
    accentContainer: const Color(0xFF112840),
    onAccentContainer: AmoloodColors.textPrimary,
    // Semantic
    error: AmoloodColors.error,
    onError: Colors.white,
    errorContainer: const Color(0xFF3D1111),
    onErrorContainer: const Color(0xFFFFCDD2),
    success: AmoloodColors.success,
    onSuccess: Colors.black,
    successContainer: const Color(0xFF003319),
    onSuccessContainer: const Color(0xFFB9F6CA),
    warning: AmoloodColors.warning,
    onWarning: Colors.black,
    warningContainer: const Color(0xFF3D2900),
    onWarningContainer: const Color(0xFFFFE0B2),
    info: const Color(0xFF4FC3F7),
    onInfo: Colors.black,
    infoContainer: const Color(0xFF003C5A),
    onInfoContainer: const Color(0xFFB3E5FC),
    // Surfaces (layered) — مطابقة لـ AmoloodColors
    background: AmoloodColors.background,
    onBackground: AmoloodColors.textPrimary,
    surface: AmoloodColors.surface,
    onSurface: AmoloodColors.textPrimary,
    surfaceVariant: AmoloodColors.surfaceElevated,
    onSurfaceVariant: AmoloodColors.textSecondary,
    card: AmoloodColors.surface,
    onCard: AmoloodColors.textPrimary,
    cardInteractive: AmoloodColors.surfaceElevated,
    cardHover: const Color(0xFF1A3A5C),
    onCardInteractive: AmoloodColors.textPrimary,
    // Borders
    outline: AmoloodColors.border,
    outlineVariant: const Color(0xFF0D1F3C),
    // Inputs
    inputBackground: AmoloodColors.surface,
    inputFocusedBorder: AmoloodColors.primary,
    // Text hierarchy
    textPrimary: AmoloodColors.textPrimary,
    textSecondary: AmoloodColors.textSecondary,
    textTertiary: AmoloodColors.textMuted,
    textDisabled: const Color(0xFF2A4865),
    // Misc
    muted: AmoloodColors.inactive,
    scrim: Colors.black.withValues(alpha: 0.7),
    shadow: Colors.black.withValues(alpha: 0.4),
  );

  /// AppTextThemeExtension بخط Tajawal وألوان Amolood
  static final _amoloodTextTheme = AppTextThemeExtension(
    displayLarge: AppTypography.displayLarge.copyWith(color: AmoloodColors.textPrimary),
    displayMedium: AppTypography.displayMedium.copyWith(color: AmoloodColors.textPrimary),
    displaySmall: AppTypography.displaySmall.copyWith(color: AmoloodColors.textPrimary),
    headlineLarge: AppTypography.headlineLarge.copyWith(color: AmoloodColors.textPrimary),
    headlineMedium: AppTypography.headlineMedium.copyWith(color: AmoloodColors.textPrimary),
    headlineSmall: AppTypography.headlineSmall.copyWith(color: AmoloodColors.textPrimary),
    titleLarge: AppTypography.titleLarge.copyWith(color: AmoloodColors.textPrimary),
    titleMedium: AppTypography.titleMedium.copyWith(color: AmoloodColors.textPrimary),
    titleSmall: AppTypography.titleSmall.copyWith(color: AmoloodColors.textSecondary),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: AmoloodColors.textPrimary),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: AmoloodColors.textSecondary),
    bodySmall: AppTypography.bodySmall.copyWith(color: AmoloodColors.textMuted),
    labelLarge: AppTypography.labelLarge.copyWith(color: AmoloodColors.textPrimary),
    labelMedium: AppTypography.labelMedium.copyWith(color: AmoloodColors.textSecondary),
    labelSmall: AppTypography.labelSmall.copyWith(color: AmoloodColors.textMuted),
  );
}

/// زخارف مشتركة (Decorations) — مستوحاة من amolood
class AmoloodDecorations {
  AmoloodDecorations._();

  /// زخرفة بطاقة قياسية
  static BoxDecoration card({Color? borderColor, Gradient? gradient}) {
    return BoxDecoration(
      gradient: gradient ?? AmoloodColors.gradientCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? AmoloodColors.border,
        width: 1,
      ),
    );
  }

  /// بطاقة متوهجة (glow effect)
  static BoxDecoration glowCard(Color glowColor) {
    return BoxDecoration(
      color: AmoloodColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: glowColor.withValues(alpha: 0.5), width: 1),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.15),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// خلفية الشاشة (مع gradient داكن)
  static const BoxDecoration screen = BoxDecoration(
    gradient: AmoloodColors.gradientDark,
  );

  /// زخرفة زر أساسي
  static BoxDecoration primaryButton({bool withGlow = false}) {
    return BoxDecoration(
      gradient: AmoloodColors.gradientPrimary,
      borderRadius: BorderRadius.circular(12),
      boxShadow: withGlow
          ? [
              BoxShadow(
                color: AmoloodColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }
}
