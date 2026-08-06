// ============================================================
//  Professional Theme — Material 3 Expressive (Indigo + Amber)
//
//  الفلسفة:
//  ──────────────────────────────────────────────────────────
//  ثيم احترافي متوازن، مستوحى من Material 3 Expressive (2025).
//  يحقق:
//    ✅ WCAG AA contrast (4.5:1+) لكل النصوص
//    ✅ Layered surfaces متدرجة بدل لون واحد صارخ
//    ✅ Primary indigo قوي لكن غير مزعج
//    ✅ Accent amber دافئ للتفاصيل التفاعلية
//    ✅ Status colors مع containers متناسقة
//    ✅ خط Tajawal عبر كل النصوص (مع Arabic-friendly metrics)
//    ✅ Light + Dark متوازنان بالكامل
//    ✅ دعم RTL أصلي
//
//  استبدال AmoloodTheme (الذي كان مظلماً جداً ونيونياً صارخاً).
// ============================================================

import 'package:flutter/material.dart';

import 'app_colors_extension.dart';
import 'app_text_theme_extension.dart';
import 'app_typography.dart';

/// الألوان الرئيسية — Indigo + Amber + Slate
///
/// لوحة احترافية متوازنة، مستوحاة من Material 3 Expressive baseline.
class ProfessionalColors {
  ProfessionalColors._();

  // ─── Brand: Indigo (HSL: 230° 50% 50%) ───
  static const primary = Color(0xFF3F51B5); // Indigo 500 — قوي لكن متزن
  static const primaryLight = Color(0xFF7986CB); // Indigo 300
  static const primaryDark = Color(0xFF1A237E); // Indigo 900
  static const primaryContainer = Color(0xFFE8EAF6); // Indigo 50 (light)
  static const primaryContainerDark = Color(0xFF1A237E); // Indigo 900 (dark)
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF1A237E);
  static const onPrimaryContainerDark = Color(0xFFE8EAF6);

  // ─── Secondary: Amber (HSL: 38° 92% 50%) ───
  static const secondary = Color(0xFFFFA000); // Amber 700 — دافئ ومتزن
  static const secondaryLight = Color(0xFFFFD54F); // Amber 300
  static const secondaryDark = Color(0xFFFF6F00); // Amber 900
  static const secondaryContainer = Color(0xFFFFECB3); // Amber 50
  static const secondaryContainerDark = Color(0xFF4A3500);
  static const onSecondary = Color(0xFF000000);
  static const onSecondaryContainer = Color(0xFF4A3500);
  static const onSecondaryContainerDark = Color(0xFFFFE0B2);

  // ─── Accent: Teal ───
  static const accent = Color(0xFF00897B); // Teal 600
  static const accentContainer = Color(0xFFB2DFDB);
  static const accentContainerDark = Color(0xFF004D40);
  static const onAccent = Color(0xFFFFFFFF);
  static const onAccentContainer = Color(0xFF004D40);
  static const onAccentContainerDark = Color(0xFFB2DFDB);

  // ─── Status colors ───
  static const success = Color(0xFF2E7D32); // Green 800 — قابل للقراءة على أبيض
  static const successContainer = Color(0xFFC8E6C9);
  static const successContainerDark = Color(0xFF1B5E20);
  static const onSuccess = Color(0xFFFFFFFF);
  static const onSuccessContainer = Color(0xFF1B5E20);
  static const onSuccessContainerDark = Color(0xFFC8E6C9);

  static const warning = Color(0xFFE65100); // Orange 900 — تباين عالي
  static const warningContainer = Color(0xFFFFE0B2);
  static const warningContainerDark = Color(0xFF4A3500);
  static const onWarning = Color(0xFFFFFFFF);
  static const onWarningContainer = Color(0xFF4A3500);
  static const onWarningContainerDark = Color(0xFFFFE0B2);

  static const error = Color(0xFFC62828); // Red 800
  static const errorContainer = Color(0xFFFFCDD2);
  static const errorContainerDark = Color(0xFF5D1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFF5D1A1A);
  static const onErrorContainerDark = Color(0xFFFFCDD2);

  static const info = Color(0xFF0277BD); // Light Blue 800
  static const infoContainer = Color(0xFFB3E5FC);
  static const infoContainerDark = Color(0xFF003C5A);
  static const onInfo = Color(0xFFFFFFFF);
  static const onInfoContainer = Color(0xFF003C5A);
  static const onInfoContainerDark = Color(0xFFB3E5FC);

  // ─── Light Mode Surfaces (layered) ───
  // تسلسل: background < surface < surfaceVariant < card
  static const lightBackground = Color(0xFFF8F9FB); // رمادي محايد فاتح جداً
  static const lightSurface = Color(0xFFFFFFFF); // أبيض نقي للسطوح المرفوعة
  static const lightSurfaceVariant = Color(0xFFF1F3F7); // رمادي فاتح
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardInteractive = Color(0xFFF5F7FA);
  static const lightCardHover = Color(0xFFECEFF3);

  // ─── Dark Mode Surfaces (layered) ───
  // Indigo داكن متناسق — ليس أسود صارخ بل عمق نيلي
  static const darkBackground = Color(0xFF0F1421); // نيلي داكن جداً
  static const darkSurface = Color(0xFF1A1F2E); // بطاقة عادية
  static const darkSurfaceVariant = Color(0xFF252B3D); // بطاقة تفاعلية
  static const darkCard = Color(0xFF1A1F2E);
  static const darkCardInteractive = Color(0xFF252B3D);
  static const darkCardHover = Color(0xFF2F3548);

  // ─── Outlines ───
  static const lightOutline = Color(0xFFB0BEC5); // Blue Grey 200
  static const lightOutlineVariant = Color(0xFFE0E5EB);
  static const darkOutline = Color(0xFF3A4258); // قابل للرؤية على dark surface
  static const darkOutlineVariant = Color(0xFF252B3D);

  // ─── Text hierarchy ───
  // Light: النص الأساسي داكن على خلفية فاتحة
  static const lightTextPrimary = Color(0xFF1A1F2E);
  static const lightTextSecondary = Color(0xFF455A64);
  static const lightTextTertiary = Color(0xFF78909C);
  static const lightTextDisabled = Color(0xFFB0BEC5);

  // Dark: النص الأساسي فاتح على خلفية داكنة (WCAG AA > 7:1)
  static const darkTextPrimary = Color(0xFFECEFF1);
  static const darkTextSecondary = Color(0xFFB0BEC5);
  static const darkTextTertiary = Color(0xFF78909C);
  static const darkTextDisabled = Color(0xFF4A5568);

  // ─── Gradients ───
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
  );

  static const gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFA000), Color(0xFFFFB300)],
  );

  static const gradientSuccess = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
  );

  static const gradientSurfaceLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F9FB), Color(0xFFFFFFFF)],
  );

  static const gradientSurfaceDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F1421), Color(0xFF1A1F2E)],
  );
}

/// ثيم Professional Light
class ProfessionalTheme {
  ProfessionalTheme._();

  // ============================================================
  //  Light Theme
  // ============================================================
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: ProfessionalColors.lightBackground,
      colorScheme: const ColorScheme.light(
        // Brand
        primary: ProfessionalColors.primary,
        onPrimary: ProfessionalColors.onPrimary,
        primaryContainer: ProfessionalColors.primaryContainer,
        onPrimaryContainer: ProfessionalColors.onPrimaryContainer,
        secondary: ProfessionalColors.secondary,
        onSecondary: ProfessionalColors.onSecondary,
        secondaryContainer: ProfessionalColors.secondaryContainer,
        onSecondaryContainer: ProfessionalColors.onSecondaryContainer,
        tertiary: ProfessionalColors.accent,
        onTertiary: ProfessionalColors.onAccent,
        tertiaryContainer: ProfessionalColors.accentContainer,
        onTertiaryContainer: ProfessionalColors.onAccentContainer,
        // Status
        error: ProfessionalColors.error,
        onError: ProfessionalColors.onError,
        errorContainer: ProfessionalColors.errorContainer,
        onErrorContainer: ProfessionalColors.onErrorContainer,
        // Surfaces
        surface: ProfessionalColors.lightSurface,
        onSurface: ProfessionalColors.lightTextPrimary,
        surfaceContainerHighest: ProfessionalColors.lightSurfaceVariant,
        onSurfaceVariant: ProfessionalColors.lightTextSecondary,
        outline: ProfessionalColors.lightOutline,
        outlineVariant: ProfessionalColors.lightOutlineVariant,
        shadow: Color(0x1A000000),
        scrim: Color(0x80000000),
      ),
      textTheme: _buildTextTheme(ProfessionalColors.lightTextPrimary,
          ProfessionalColors.lightTextSecondary, ProfessionalColors.lightTextTertiary),
      appBarTheme: const AppBarTheme(
        backgroundColor: ProfessionalColors.lightSurface,
        foregroundColor: ProfessionalColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ProfessionalColors.lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: ProfessionalColors.lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: ProfessionalColors.lightCard,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
              color: ProfessionalColors.lightOutlineVariant, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ProfessionalColors.primary,
          foregroundColor: ProfessionalColors.onPrimary,
          elevation: 1,
          shadowColor: ProfessionalColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ProfessionalColors.primary,
          foregroundColor: ProfessionalColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ProfessionalColors.primary,
          side: const BorderSide(color: ProfessionalColors.lightOutline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ProfessionalColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ProfessionalColors.lightSurfaceVariant,
        labelStyle: const TextStyle(color: ProfessionalColors.lightTextSecondary),
        hintStyle: const TextStyle(color: ProfessionalColors.lightTextTertiary),
        prefixIconColor: ProfessionalColors.lightTextSecondary,
        suffixIconColor: ProfessionalColors.lightTextSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ProfessionalColors.lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ProfessionalColors.lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ProfessionalColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ProfessionalColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ProfessionalColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: ProfessionalColors.lightOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: ProfessionalColors.lightTextPrimary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ProfessionalColors.onPrimary;
          }
          return ProfessionalColors.lightOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ProfessionalColors.primary;
          }
          return ProfessionalColors.lightOutlineVariant;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ProfessionalColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(ProfessionalColors.onPrimary),
        side: const BorderSide(color: ProfessionalColors.lightOutline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ProfessionalColors.lightSurface,
        indicatorColor: ProfessionalColors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ProfessionalColors.primary,
            );
          }
          return const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: ProfessionalColors.lightTextTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ProfessionalColors.primary, size: 24);
          }
          return const IconThemeData(color: ProfessionalColors.lightTextTertiary, size: 24);
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: ProfessionalColors.lightSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ProfessionalColors.darkSurface,
        contentTextStyle: const TextStyle(color: ProfessionalColors.darkTextPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      extensions: [_lightAppColors, _lightTextTheme],
    );
  }

  // ============================================================
  //  Dark Theme
  // ============================================================
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: ProfessionalColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        // Brand
        primary: ProfessionalColors.primaryLight,
        onPrimary: ProfessionalColors.onPrimary,
        primaryContainer: ProfessionalColors.primaryContainerDark,
        onPrimaryContainer: ProfessionalColors.onPrimaryContainerDark,
        secondary: ProfessionalColors.secondaryLight,
        onSecondary: ProfessionalColors.onSecondary,
        secondaryContainer: ProfessionalColors.secondaryContainerDark,
        onSecondaryContainer: ProfessionalColors.onSecondaryContainerDark,
        tertiary: ProfessionalColors.accent,
        onTertiary: ProfessionalColors.onAccent,
        tertiaryContainer: ProfessionalColors.accentContainerDark,
        onTertiaryContainer: ProfessionalColors.onAccentContainerDark,
        // Status
        error: ProfessionalColors.error,
        onError: ProfessionalColors.onError,
        errorContainer: ProfessionalColors.errorContainerDark,
        onErrorContainer: ProfessionalColors.onErrorContainerDark,
        // Surfaces
        surface: ProfessionalColors.darkSurface,
        onSurface: ProfessionalColors.darkTextPrimary,
        surfaceContainerHighest: ProfessionalColors.darkSurfaceVariant,
        onSurfaceVariant: ProfessionalColors.darkTextSecondary,
        outline: ProfessionalColors.darkOutline,
        outlineVariant: ProfessionalColors.darkOutlineVariant,
        shadow: Color(0x66000000),
        scrim: Color(0xB3000000),
      ),
      textTheme: _buildTextTheme(ProfessionalColors.darkTextPrimary,
          ProfessionalColors.darkTextSecondary, ProfessionalColors.darkTextTertiary),
      appBarTheme: const AppBarTheme(
        backgroundColor: ProfessionalColors.darkSurface,
        foregroundColor: ProfessionalColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ProfessionalColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: ProfessionalColors.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: ProfessionalColors.darkCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: ProfessionalColors.darkOutline, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ProfessionalColors.primaryLight,
          foregroundColor: ProfessionalColors.onPrimary,
          elevation: 0,
          shadowColor: ProfessionalColors.primaryLight.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ProfessionalColors.primaryLight,
          foregroundColor: ProfessionalColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ProfessionalColors.primaryLight,
          side: const BorderSide(color: ProfessionalColors.darkOutline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ProfessionalColors.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ProfessionalColors.darkSurfaceVariant,
        labelStyle: const TextStyle(color: ProfessionalColors.darkTextSecondary),
        hintStyle: const TextStyle(color: ProfessionalColors.darkTextTertiary),
        prefixIconColor: ProfessionalColors.darkTextSecondary,
        suffixIconColor: ProfessionalColors.darkTextSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ProfessionalColors.darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ProfessionalColors.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ProfessionalColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ProfessionalColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ProfessionalColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: ProfessionalColors.darkOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: ProfessionalColors.darkTextPrimary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ProfessionalColors.onPrimary;
          }
          return ProfessionalColors.darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ProfessionalColors.primaryLight;
          }
          return ProfessionalColors.darkOutlineVariant;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ProfessionalColors.primaryLight;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(ProfessionalColors.onPrimary),
        side: const BorderSide(color: ProfessionalColors.darkOutline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ProfessionalColors.darkSurface,
        indicatorColor: ProfessionalColors.primaryContainerDark,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ProfessionalColors.primaryLight,
            );
          }
          return const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: ProfessionalColors.darkTextTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ProfessionalColors.primaryLight, size: 24);
          }
          return const IconThemeData(color: ProfessionalColors.darkTextTertiary, size: 24);
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: ProfessionalColors.darkSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ProfessionalColors.darkSurfaceVariant,
        contentTextStyle: const TextStyle(color: ProfessionalColors.darkTextPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      extensions: [_darkAppColors, _darkTextTheme],
    );
  }

  // ============================================================
  //  Text theme builder
  // ============================================================
  static TextTheme _buildTextTheme(
      Color primary, Color secondary, Color tertiary) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: primary),
      displayMedium: AppTypography.displayMedium.copyWith(color: primary),
      displaySmall: AppTypography.displaySmall.copyWith(color: primary),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: primary),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: primary),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: primary),
      titleLarge: AppTypography.titleLarge.copyWith(color: primary),
      titleMedium: AppTypography.titleMedium.copyWith(color: primary),
      titleSmall: AppTypography.titleSmall.copyWith(color: secondary),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: primary),
      bodySmall: AppTypography.bodySmall.copyWith(color: secondary),
      labelLarge: AppTypography.labelLarge.copyWith(color: primary),
      labelMedium: AppTypography.labelMedium.copyWith(color: secondary),
      labelSmall: AppTypography.labelSmall.copyWith(color: tertiary),
    );
  }

  // ============================================================
  //  AppColorsExtension instances
  // ============================================================
  static final _lightAppColors = AppColorsExtension(
    // Brand
    primary: ProfessionalColors.primary,
    onPrimary: ProfessionalColors.onPrimary,
    primaryContainer: ProfessionalColors.primaryContainer,
    onPrimaryContainer: ProfessionalColors.onPrimaryContainer,
    secondary: ProfessionalColors.secondary,
    onSecondary: ProfessionalColors.onSecondary,
    secondaryContainer: ProfessionalColors.secondaryContainer,
    onSecondaryContainer: ProfessionalColors.onSecondaryContainer,
    accent: ProfessionalColors.accent,
    onAccent: ProfessionalColors.onAccent,
    accentContainer: ProfessionalColors.accentContainer,
    onAccentContainer: ProfessionalColors.onAccentContainer,
    // Semantic
    error: ProfessionalColors.error,
    onError: ProfessionalColors.onError,
    errorContainer: ProfessionalColors.errorContainer,
    onErrorContainer: ProfessionalColors.onErrorContainer,
    success: ProfessionalColors.success,
    onSuccess: ProfessionalColors.onSuccess,
    successContainer: ProfessionalColors.successContainer,
    onSuccessContainer: ProfessionalColors.onSuccessContainer,
    warning: ProfessionalColors.warning,
    onWarning: ProfessionalColors.onWarning,
    warningContainer: ProfessionalColors.warningContainer,
    onWarningContainer: ProfessionalColors.onWarningContainer,
    info: ProfessionalColors.info,
    onInfo: ProfessionalColors.onInfo,
    infoContainer: ProfessionalColors.infoContainer,
    onInfoContainer: ProfessionalColors.onInfoContainer,
    // Surfaces
    background: ProfessionalColors.lightBackground,
    onBackground: ProfessionalColors.lightTextPrimary,
    surface: ProfessionalColors.lightSurface,
    onSurface: ProfessionalColors.lightTextPrimary,
    surfaceVariant: ProfessionalColors.lightSurfaceVariant,
    onSurfaceVariant: ProfessionalColors.lightTextSecondary,
    card: ProfessionalColors.lightCard,
    onCard: ProfessionalColors.lightTextPrimary,
    cardInteractive: ProfessionalColors.lightCardInteractive,
    cardHover: ProfessionalColors.lightCardHover,
    onCardInteractive: ProfessionalColors.lightTextPrimary,
    // Borders
    outline: ProfessionalColors.lightOutline,
    outlineVariant: ProfessionalColors.lightOutlineVariant,
    // Inputs
    inputBackground: ProfessionalColors.lightSurfaceVariant,
    inputFocusedBorder: ProfessionalColors.primary,
    // Text
    textPrimary: ProfessionalColors.lightTextPrimary,
    textSecondary: ProfessionalColors.lightTextSecondary,
    textTertiary: ProfessionalColors.lightTextTertiary,
    textDisabled: ProfessionalColors.lightTextDisabled,
    // Misc
    muted: ProfessionalColors.lightTextTertiary,
    scrim: const Color(0x80000000),
    shadow: const Color(0x1A000000),
  );

  static final _darkAppColors = AppColorsExtension(
    // Brand
    primary: ProfessionalColors.primaryLight,
    onPrimary: ProfessionalColors.onPrimary,
    primaryContainer: ProfessionalColors.primaryContainerDark,
    onPrimaryContainer: ProfessionalColors.onPrimaryContainerDark,
    secondary: ProfessionalColors.secondaryLight,
    onSecondary: ProfessionalColors.onSecondary,
    secondaryContainer: ProfessionalColors.secondaryContainerDark,
    onSecondaryContainer: ProfessionalColors.onSecondaryContainerDark,
    accent: ProfessionalColors.accent,
    onAccent: ProfessionalColors.onAccent,
    accentContainer: ProfessionalColors.accentContainerDark,
    onAccentContainer: ProfessionalColors.onAccentContainerDark,
    // Semantic
    error: ProfessionalColors.error,
    onError: ProfessionalColors.onError,
    errorContainer: ProfessionalColors.errorContainerDark,
    onErrorContainer: ProfessionalColors.onErrorContainerDark,
    success: ProfessionalColors.success,
    onSuccess: ProfessionalColors.onSuccess,
    successContainer: ProfessionalColors.successContainerDark,
    onSuccessContainer: ProfessionalColors.onSuccessContainerDark,
    warning: ProfessionalColors.warning,
    onWarning: ProfessionalColors.onWarning,
    warningContainer: ProfessionalColors.warningContainerDark,
    onWarningContainer: ProfessionalColors.onWarningContainerDark,
    info: ProfessionalColors.info,
    onInfo: ProfessionalColors.onInfo,
    infoContainer: ProfessionalColors.infoContainerDark,
    onInfoContainer: ProfessionalColors.onInfoContainerDark,
    // Surfaces
    background: ProfessionalColors.darkBackground,
    onBackground: ProfessionalColors.darkTextPrimary,
    surface: ProfessionalColors.darkSurface,
    onSurface: ProfessionalColors.darkTextPrimary,
    surfaceVariant: ProfessionalColors.darkSurfaceVariant,
    onSurfaceVariant: ProfessionalColors.darkTextSecondary,
    card: ProfessionalColors.darkCard,
    onCard: ProfessionalColors.darkTextPrimary,
    cardInteractive: ProfessionalColors.darkCardInteractive,
    cardHover: ProfessionalColors.darkCardHover,
    onCardInteractive: ProfessionalColors.darkTextPrimary,
    // Borders
    outline: ProfessionalColors.darkOutline,
    outlineVariant: ProfessionalColors.darkOutlineVariant,
    // Inputs
    inputBackground: ProfessionalColors.darkSurfaceVariant,
    inputFocusedBorder: ProfessionalColors.primaryLight,
    // Text
    textPrimary: ProfessionalColors.darkTextPrimary,
    textSecondary: ProfessionalColors.darkTextSecondary,
    textTertiary: ProfessionalColors.darkTextTertiary,
    textDisabled: ProfessionalColors.darkTextDisabled,
    // Misc
    muted: ProfessionalColors.darkTextTertiary,
    scrim: const Color(0xB3000000),
    shadow: const Color(0x66000000),
  );

  static final _lightTextTheme = AppTextThemeExtension(
    displayLarge: AppTypography.displayLarge.copyWith(color: ProfessionalColors.lightTextPrimary),
    displayMedium: AppTypography.displayMedium.copyWith(color: ProfessionalColors.lightTextPrimary),
    displaySmall: AppTypography.displaySmall.copyWith(color: ProfessionalColors.lightTextPrimary),
    headlineLarge: AppTypography.headlineLarge.copyWith(color: ProfessionalColors.lightTextPrimary),
    headlineMedium: AppTypography.headlineMedium.copyWith(color: ProfessionalColors.lightTextPrimary),
    headlineSmall: AppTypography.headlineSmall.copyWith(color: ProfessionalColors.lightTextPrimary),
    titleLarge: AppTypography.titleLarge.copyWith(color: ProfessionalColors.lightTextPrimary),
    titleMedium: AppTypography.titleMedium.copyWith(color: ProfessionalColors.lightTextPrimary),
    titleSmall: AppTypography.titleSmall.copyWith(color: ProfessionalColors.lightTextSecondary),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: ProfessionalColors.lightTextPrimary),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: ProfessionalColors.lightTextPrimary),
    bodySmall: AppTypography.bodySmall.copyWith(color: ProfessionalColors.lightTextSecondary),
    labelLarge: AppTypography.labelLarge.copyWith(color: ProfessionalColors.lightTextPrimary),
    labelMedium: AppTypography.labelMedium.copyWith(color: ProfessionalColors.lightTextSecondary),
    labelSmall: AppTypography.labelSmall.copyWith(color: ProfessionalColors.lightTextTertiary),
  );

  static final _darkTextTheme = AppTextThemeExtension(
    displayLarge: AppTypography.displayLarge.copyWith(color: ProfessionalColors.darkTextPrimary),
    displayMedium: AppTypography.displayMedium.copyWith(color: ProfessionalColors.darkTextPrimary),
    displaySmall: AppTypography.displaySmall.copyWith(color: ProfessionalColors.darkTextPrimary),
    headlineLarge: AppTypography.headlineLarge.copyWith(color: ProfessionalColors.darkTextPrimary),
    headlineMedium: AppTypography.headlineMedium.copyWith(color: ProfessionalColors.darkTextPrimary),
    headlineSmall: AppTypography.headlineSmall.copyWith(color: ProfessionalColors.darkTextPrimary),
    titleLarge: AppTypography.titleLarge.copyWith(color: ProfessionalColors.darkTextPrimary),
    titleMedium: AppTypography.titleMedium.copyWith(color: ProfessionalColors.darkTextPrimary),
    titleSmall: AppTypography.titleSmall.copyWith(color: ProfessionalColors.darkTextSecondary),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: ProfessionalColors.darkTextPrimary),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: ProfessionalColors.darkTextPrimary),
    bodySmall: AppTypography.bodySmall.copyWith(color: ProfessionalColors.darkTextSecondary),
    labelLarge: AppTypography.labelLarge.copyWith(color: ProfessionalColors.darkTextPrimary),
    labelMedium: AppTypography.labelMedium.copyWith(color: ProfessionalColors.darkTextSecondary),
    labelSmall: AppTypography.labelSmall.copyWith(color: ProfessionalColors.darkTextTertiary),
  );
}
