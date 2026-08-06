import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors_extension.dart';
import 'app_text_theme_extension.dart';
import 'app_typography.dart';
import 'app_palette.dart';

// ============================================================
//  AppTheme v2 — Restructured Theme System
//
//  Features:
//  - Light + Dark themes متناسقة بالكامل
//  - AppColorsExtension شامل (semantic tokens)
//  - Text hierarchy (4 مستويات)
//  - Layered surfaces (background < surface < surfaceVariant < card)
//  - CardThemeData, AppBarTheme, InputDecorationTheme متناسقة
//  - Switching state محفوظ في SharedPreferences
//
//  Usage in MaterialApp:
//  ```dart
//  ChangeNotifierProvider(
//    create: (context) => AppTheme(),
//    child: Consumer<AppTheme>(
//      builder: (context, themeProvider, child) => MaterialApp(
//        theme: AppTheme.light,
//        darkTheme: AppTheme.dark,
//        themeMode: themeProvider.themeMode,
//      ),
//    ),
//  )
//  ```
// ============================================================

class AppTheme with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Initialize theme from saved preference
  Future<void> initialize() async {
    await _loadThemeFromPrefs();
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Set specific theme mode and save to preferences
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();
    await _saveThemeToPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeModeKey);
      if (savedThemeIndex != null &&
          savedThemeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[savedThemeIndex];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, _themeMode.index);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;

  // ============================================================
  //  Light Theme
  // ============================================================
  static final light = () {
    final defaultTheme = ThemeData.light();

    return defaultTheme.copyWith(
      scaffoldBackgroundColor: AppPalette.lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppPalette.primary,
        onPrimary: AppPalette.onPrimary,
        primaryContainer: AppPalette.primaryContainer,
        onPrimaryContainer: AppPalette.onPrimaryContainer,
        secondary: AppPalette.secondary,
        onSecondary: AppPalette.onSecondary,
        secondaryContainer: AppPalette.secondaryContainer,
        onSecondaryContainer: AppPalette.onSecondaryContainer,
        tertiary: AppPalette.accent,
        onTertiary: AppPalette.onAccent,
        tertiaryContainer: AppPalette.accentContainer,
        onTertiaryContainer: AppPalette.onAccentContainer,
        error: AppPalette.error,
        onError: AppPalette.onError,
        errorContainer: AppPalette.errorContainer,
        onErrorContainer: AppPalette.onErrorContainer,
        surface: AppPalette.lightSurface,
        onSurface: AppPalette.lightTextPrimary,
        surfaceContainerHighest: AppPalette.lightSurfaceVariant,
        onSurfaceVariant: AppPalette.lightTextSecondary,
        outline: AppPalette.lightOutline,
        outlineVariant: AppPalette.lightOutlineVariant,
        shadow: Colors.black.withValues(alpha: 0.1),
        scrim: Colors.black.withValues(alpha: 0.5),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge
            .copyWith(color: AppPalette.lightTextPrimary),
        displayMedium: AppTypography.displayMedium
            .copyWith(color: AppPalette.lightTextPrimary),
        displaySmall: AppTypography.displaySmall
            .copyWith(color: AppPalette.lightTextPrimary),
        headlineLarge: AppTypography.headlineLarge
            .copyWith(color: AppPalette.lightTextPrimary),
        headlineMedium: AppTypography.headlineMedium
            .copyWith(color: AppPalette.lightTextPrimary),
        headlineSmall: AppTypography.headlineSmall
            .copyWith(color: AppPalette.lightTextPrimary),
        titleLarge: AppTypography.titleLarge
            .copyWith(color: AppPalette.lightTextPrimary),
        titleMedium: AppTypography.titleMedium
            .copyWith(color: AppPalette.lightTextPrimary),
        titleSmall: AppTypography.titleSmall
            .copyWith(color: AppPalette.lightTextSecondary),
        bodyLarge: AppTypography.bodyLarge
            .copyWith(color: AppPalette.lightTextPrimary),
        bodyMedium: AppTypography.bodyMedium
            .copyWith(color: AppPalette.lightTextPrimary),
        bodySmall: AppTypography.bodySmall
            .copyWith(color: AppPalette.lightTextSecondary),
        labelLarge: AppTypography.labelLarge
            .copyWith(color: AppPalette.lightTextPrimary),
        labelMedium: AppTypography.labelMedium
            .copyWith(color: AppPalette.lightTextSecondary),
        labelSmall: AppTypography.labelSmall
            .copyWith(color: AppPalette.lightTextTertiary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.lightSurface,
        foregroundColor: AppPalette.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppPalette.lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppPalette.lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: AppPalette.lightCard,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppPalette.lightOutlineVariant, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: AppPalette.onPrimary,
          elevation: 0,
          shadowColor: AppPalette.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: AppPalette.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.primary,
          side: const BorderSide(color: AppPalette.lightOutline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.lightSurfaceVariant,
        labelStyle: const TextStyle(color: AppPalette.lightTextSecondary),
        hintStyle: const TextStyle(color: AppPalette.lightTextTertiary),
        prefixIconColor: AppPalette.lightTextSecondary,
        suffixIconColor: AppPalette.lightTextSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.lightSurfaceVariant,
        labelStyle: const TextStyle(color: AppPalette.lightTextPrimary),
        side: const BorderSide(color: AppPalette.lightOutlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        selectedColor: AppPalette.primary,
        checkmarkColor: AppPalette.onPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.lightOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppPalette.lightTextPrimary,
        size: 24,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppPalette.lightSurface,
        selectedItemColor: AppPalette.primary,
        unselectedItemColor: AppPalette.lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppPalette.lightSurface,
        selectedIconTheme: IconThemeData(color: AppPalette.primary),
        unselectedIconTheme: IconThemeData(color: AppPalette.lightTextTertiary),
        selectedLabelTextStyle: TextStyle(color: AppPalette.primary),
        unselectedLabelTextStyle:
            TextStyle(color: AppPalette.lightTextTertiary),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppPalette.lightSurface,
        scrimColor: Colors.black.withValues(alpha: 0.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.lightTextPrimary,
        contentTextStyle: const TextStyle(color: AppPalette.lightSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      extensions: [
        _lightAppColors,
        _lightTextTheme,
      ],
    );
  }();

  static final _lightAppColors = AppColorsExtension(
    // Brand
    primary: AppPalette.primary,
    onPrimary: AppPalette.onPrimary,
    primaryContainer: AppPalette.primaryContainer,
    onPrimaryContainer: AppPalette.onPrimaryContainer,
    secondary: AppPalette.secondary,
    onSecondary: AppPalette.onSecondary,
    secondaryContainer: AppPalette.secondaryContainer,
    onSecondaryContainer: AppPalette.onSecondaryContainer,
    accent: AppPalette.accent,
    onAccent: AppPalette.onAccent,
    accentContainer: AppPalette.accentContainer,
    onAccentContainer: AppPalette.onAccentContainer,
    // Semantic
    error: AppPalette.error,
    onError: AppPalette.onError,
    errorContainer: AppPalette.errorContainer,
    onErrorContainer: AppPalette.onErrorContainer,
    success: AppPalette.success,
    onSuccess: AppPalette.onSuccess,
    successContainer: AppPalette.successContainer,
    onSuccessContainer: AppPalette.onSuccessContainer,
    warning: AppPalette.warning,
    onWarning: AppPalette.onWarning,
    warningContainer: AppPalette.warningContainer,
    onWarningContainer: AppPalette.onWarningContainer,
    info: AppPalette.info,
    onInfo: AppPalette.onInfo,
    infoContainer: AppPalette.infoContainer,
    onInfoContainer: AppPalette.onInfoContainer,
    // Surfaces
    background: AppPalette.lightBackground,
    onBackground: AppPalette.lightTextPrimary,
    surface: AppPalette.lightSurface,
    onSurface: AppPalette.lightTextPrimary,
    surfaceVariant: AppPalette.lightSurfaceVariant,
    onSurfaceVariant: AppPalette.lightTextSecondary,
    card: AppPalette.lightCard,
    onCard: AppPalette.lightTextPrimary,
    cardInteractive: AppPalette.lightCardInteractive,
    cardHover: AppPalette.lightCardHover,
    onCardInteractive: AppPalette.lightTextPrimary,
    // Borders
    outline: AppPalette.lightOutline,
    outlineVariant: AppPalette.lightOutlineVariant,
    // Inputs
    inputBackground: AppPalette.lightSurfaceVariant,
    inputFocusedBorder: AppPalette.primary,
    // Text hierarchy
    textPrimary: AppPalette.lightTextPrimary,
    textSecondary: AppPalette.lightTextSecondary,
    textTertiary: AppPalette.lightTextTertiary,
    textDisabled: AppPalette.lightTextDisabled,
    // Misc
    muted: AppPalette.muted,
    scrim: Colors.black.withValues(alpha: 0.5),
    shadow: Colors.black.withValues(alpha: 0.1),
  );

  static final _lightTextTheme = AppTextThemeExtension(
    displayLarge:
        AppTypography.displayLarge.copyWith(color: _lightAppColors.textPrimary),
    displayMedium: AppTypography.displayMedium
        .copyWith(color: _lightAppColors.textPrimary),
    displaySmall:
        AppTypography.displaySmall.copyWith(color: _lightAppColors.textPrimary),
    headlineLarge: AppTypography.headlineLarge
        .copyWith(color: _lightAppColors.textPrimary),
    headlineMedium: AppTypography.headlineMedium
        .copyWith(color: _lightAppColors.textPrimary),
    headlineSmall: AppTypography.headlineSmall
        .copyWith(color: _lightAppColors.textPrimary),
    titleLarge:
        AppTypography.titleLarge.copyWith(color: _lightAppColors.textPrimary),
    titleMedium:
        AppTypography.titleMedium.copyWith(color: _lightAppColors.textPrimary),
    titleSmall:
        AppTypography.titleSmall.copyWith(color: _lightAppColors.textSecondary),
    bodyLarge:
        AppTypography.bodyLarge.copyWith(color: _lightAppColors.textPrimary),
    bodyMedium:
        AppTypography.bodyMedium.copyWith(color: _lightAppColors.textPrimary),
    bodySmall:
        AppTypography.bodySmall.copyWith(color: _lightAppColors.textSecondary),
    labelLarge:
        AppTypography.labelLarge.copyWith(color: _lightAppColors.textPrimary),
    labelMedium: AppTypography.labelMedium
        .copyWith(color: _lightAppColors.textSecondary),
    labelSmall:
        AppTypography.labelSmall.copyWith(color: _lightAppColors.textTertiary),
  );

  // ============================================================
  //  Dark Theme — الأساسي (Dark Navy + Teal متناسق)
  // ============================================================
  static final dark = () {
    final defaultTheme = ThemeData.dark();

    return defaultTheme.copyWith(
      scaffoldBackgroundColor: AppPalette.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppPalette.primaryLight,
        onPrimary: AppPalette.onPrimary,
        primaryContainer: AppPalette.primaryContainerDark,
        onPrimaryContainer: AppPalette.onPrimaryContainerDark,
        secondary: AppPalette.secondaryLight,
        onSecondary: AppPalette.onSecondary,
        secondaryContainer: AppPalette.secondaryContainerDark,
        onSecondaryContainer: AppPalette.onSecondaryContainerDark,
        tertiary: AppPalette.accent,
        onTertiary: AppPalette.onAccent,
        tertiaryContainer: AppPalette.accentContainerDark,
        onTertiaryContainer: AppPalette.onAccentContainerDark,
        error: AppPalette.error,
        onError: AppPalette.onError,
        errorContainer: AppPalette.errorContainerDark,
        onErrorContainer: AppPalette.onErrorContainerDark,
        surface: AppPalette.darkSurface,
        onSurface: AppPalette.darkTextPrimary,
        surfaceContainerHighest: AppPalette.darkSurfaceVariant,
        onSurfaceVariant: AppPalette.darkTextSecondary,
        outline: AppPalette.darkOutline,
        outlineVariant: AppPalette.darkOutlineVariant,
        shadow: Colors.black.withValues(alpha: 0.4),
        scrim: Colors.black.withValues(alpha: 0.7),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge
            .copyWith(color: AppPalette.darkTextPrimary),
        displayMedium: AppTypography.displayMedium
            .copyWith(color: AppPalette.darkTextPrimary),
        displaySmall: AppTypography.displaySmall
            .copyWith(color: AppPalette.darkTextPrimary),
        headlineLarge: AppTypography.headlineLarge
            .copyWith(color: AppPalette.darkTextPrimary),
        headlineMedium: AppTypography.headlineMedium
            .copyWith(color: AppPalette.darkTextPrimary),
        headlineSmall: AppTypography.headlineSmall
            .copyWith(color: AppPalette.darkTextPrimary),
        titleLarge: AppTypography.titleLarge
            .copyWith(color: AppPalette.darkTextPrimary),
        titleMedium: AppTypography.titleMedium
            .copyWith(color: AppPalette.darkTextPrimary),
        titleSmall: AppTypography.titleSmall
            .copyWith(color: AppPalette.darkTextSecondary),
        bodyLarge:
            AppTypography.bodyLarge.copyWith(color: AppPalette.darkTextPrimary),
        bodyMedium: AppTypography.bodyMedium
            .copyWith(color: AppPalette.darkTextPrimary),
        bodySmall: AppTypography.bodySmall
            .copyWith(color: AppPalette.darkTextSecondary),
        labelLarge: AppTypography.labelLarge
            .copyWith(color: AppPalette.darkTextPrimary),
        labelMedium: AppTypography.labelMedium
            .copyWith(color: AppPalette.darkTextSecondary),
        labelSmall: AppTypography.labelSmall
            .copyWith(color: AppPalette.darkTextTertiary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.darkBackground,
        foregroundColor: AppPalette.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppPalette.darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppPalette.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppPalette.darkCard,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppPalette.darkOutlineVariant, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primaryLight,
          foregroundColor: AppPalette.onPrimary,
          elevation: 0,
          shadowColor: AppPalette.primaryLight.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primaryLight,
          foregroundColor: AppPalette.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.primaryLight,
          side: const BorderSide(color: AppPalette.darkOutline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.darkSurfaceVariant,
        labelStyle: const TextStyle(color: AppPalette.darkTextSecondary),
        hintStyle: const TextStyle(color: AppPalette.darkTextTertiary),
        prefixIconColor: AppPalette.darkTextSecondary,
        suffixIconColor: AppPalette.darkTextSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppPalette.primaryLight,
        foregroundColor: AppPalette.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.darkSurfaceVariant,
        labelStyle: const TextStyle(color: AppPalette.darkTextPrimary),
        side: const BorderSide(color: AppPalette.darkOutlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        selectedColor: AppPalette.primaryLight,
        checkmarkColor: AppPalette.onPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.darkOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppPalette.darkTextPrimary,
        size: 24,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppPalette.darkSurface,
        selectedItemColor: AppPalette.primaryLight,
        unselectedItemColor: AppPalette.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppPalette.darkSurface,
        selectedIconTheme: IconThemeData(color: AppPalette.primaryLight),
        unselectedIconTheme: IconThemeData(color: AppPalette.darkTextTertiary),
        selectedLabelTextStyle: TextStyle(color: AppPalette.primaryLight),
        unselectedLabelTextStyle: TextStyle(color: AppPalette.darkTextTertiary),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppPalette.darkSurface,
        scrimColor: Colors.black.withValues(alpha: 0.7),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.darkSurfaceVariant,
        contentTextStyle: const TextStyle(color: AppPalette.darkTextPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      extensions: [
        _darkAppColors,
        _darkTextTheme,
      ],
    );
  }();

  static final _darkAppColors = AppColorsExtension(
    // Brand
    primary: AppPalette.primaryLight,
    onPrimary: AppPalette.onPrimary,
    primaryContainer: AppPalette.primaryContainerDark,
    onPrimaryContainer: AppPalette.onPrimaryContainerDark,
    secondary: AppPalette.secondaryLight,
    onSecondary: AppPalette.onSecondary,
    secondaryContainer: AppPalette.secondaryContainerDark,
    onSecondaryContainer: AppPalette.onSecondaryContainerDark,
    accent: AppPalette.accent,
    onAccent: AppPalette.onAccent,
    accentContainer: AppPalette.accentContainerDark,
    onAccentContainer: AppPalette.onAccentContainerDark,
    // Semantic
    error: AppPalette.error,
    onError: AppPalette.onError,
    errorContainer: AppPalette.errorContainerDark,
    onErrorContainer: AppPalette.onErrorContainerDark,
    success: AppPalette.success,
    onSuccess: AppPalette.onSuccess,
    successContainer: AppPalette.successContainerDark,
    onSuccessContainer: AppPalette.onSuccessContainerDark,
    warning: AppPalette.warning,
    onWarning: AppPalette.onWarning,
    warningContainer: AppPalette.warningContainerDark,
    onWarningContainer: AppPalette.onWarningContainerDark,
    info: AppPalette.info,
    onInfo: AppPalette.onInfo,
    infoContainer: AppPalette.infoContainerDark,
    onInfoContainer: AppPalette.onInfoContainerDark,
    // Surfaces
    background: AppPalette.darkBackground,
    onBackground: AppPalette.darkTextPrimary,
    surface: AppPalette.darkSurface,
    onSurface: AppPalette.darkTextPrimary,
    surfaceVariant: AppPalette.darkSurfaceVariant,
    onSurfaceVariant: AppPalette.darkTextSecondary,
    card: AppPalette.darkCard,
    onCard: AppPalette.darkTextPrimary,
    cardInteractive: AppPalette.darkCardInteractive,
    cardHover: AppPalette.darkCardHover,
    onCardInteractive: AppPalette.darkTextPrimary,
    // Borders
    outline: AppPalette.darkOutline,
    outlineVariant: AppPalette.darkOutlineVariant,
    // Inputs
    inputBackground: AppPalette.darkSurfaceVariant,
    inputFocusedBorder: AppPalette.primaryLight,
    // Text hierarchy
    textPrimary: AppPalette.darkTextPrimary,
    textSecondary: AppPalette.darkTextSecondary,
    textTertiary: AppPalette.darkTextTertiary,
    textDisabled: AppPalette.darkTextDisabled,
    // Misc
    muted: AppPalette.darkTextTertiary,
    scrim: Colors.black.withValues(alpha: 0.7),
    shadow: Colors.black.withValues(alpha: 0.4),
  );

  static final _darkTextTheme = AppTextThemeExtension(
    displayLarge:
        AppTypography.displayLarge.copyWith(color: _darkAppColors.textPrimary),
    displayMedium:
        AppTypography.displayMedium.copyWith(color: _darkAppColors.textPrimary),
    displaySmall:
        AppTypography.displaySmall.copyWith(color: _darkAppColors.textPrimary),
    headlineLarge:
        AppTypography.headlineLarge.copyWith(color: _darkAppColors.textPrimary),
    headlineMedium: AppTypography.headlineMedium
        .copyWith(color: _darkAppColors.textPrimary),
    headlineSmall:
        AppTypography.headlineSmall.copyWith(color: _darkAppColors.textPrimary),
    titleLarge:
        AppTypography.titleLarge.copyWith(color: _darkAppColors.textPrimary),
    titleMedium:
        AppTypography.titleMedium.copyWith(color: _darkAppColors.textPrimary),
    titleSmall:
        AppTypography.titleSmall.copyWith(color: _darkAppColors.textSecondary),
    bodyLarge:
        AppTypography.bodyLarge.copyWith(color: _darkAppColors.textPrimary),
    bodyMedium:
        AppTypography.bodyMedium.copyWith(color: _darkAppColors.textPrimary),
    bodySmall:
        AppTypography.bodySmall.copyWith(color: _darkAppColors.textSecondary),
    labelLarge:
        AppTypography.labelLarge.copyWith(color: _darkAppColors.textPrimary),
    labelMedium:
        AppTypography.labelMedium.copyWith(color: _darkAppColors.textSecondary),
    labelSmall:
        AppTypography.labelSmall.copyWith(color: _darkAppColors.textTertiary),
  );
}

// ============================================================
//  Extensions للوصول إلى الثيم بسهولة
// ============================================================

/// الوصول الآمن إلى AppColorsExtension من ThemeData
///
/// الاستخدام: `Theme.of(context).appColors.primary`
extension AppThemeExtension on ThemeData {
  AppColorsExtension get appColors =>
      extension<AppColorsExtension>() ?? AppTheme._lightAppColors;

  AppTextThemeExtension get appTextTheme =>
      extension<AppTextThemeExtension>() ?? AppTheme._lightTextTheme;
}

/// طريقة مختصرة للوصول إلى ThemeData من BuildContext
///
/// الاستخدام: `context.theme.appColors.primary`
extension ThemeGetter on BuildContext {
  ThemeData get theme => Theme.of(this);

  /// shortcut للوصول السريع إلى AppColorsExtension
  AppColorsExtension get appColors => Theme.of(this).appColors;
}
