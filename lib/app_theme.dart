import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// نظام التصميم المركزي لتطبيق إدارة MikroTik.
/// يعتمد لوحة داكنة عالية التباين مناسبة للوحات التشغيل والشبكات.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF5B5CE2);
  static const Color secondaryColor = Color(0xFF25B6A1);
  static const Color scaffoldBg = Color(0xFF0B1020);
  static const Color cardBg = Color(0xFF151D32);
  static const Color subtitleGrey = Color(0xFF9AA7C2);
  static const Color successColor = Color(0xFF38C793);
  static const Color warningColor = Color(0xFFF6B756);
  static const Color dangerColor = Color(0xFFF26D85);
  static const Color inputBg = Color(0xFF111A2E);
  static const Color inputText = Color(0xFFF4F7FF);
  static const Color inputHint = Color(0xFFB4C0D9);
  static const Color inputBorder = Color(0xFF34415E);

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
    primary: primaryColor,
    secondary: secondaryColor,
    surface: cardBg,
    error: dangerColor,
  );

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkScheme,
    );
    final typography = GoogleFonts.tajawalTextTheme(baseTheme.textTheme).apply(
      bodyColor: _darkScheme.onSurface,
      displayColor: _darkScheme.onSurface,
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: typography.copyWith(
        displaySmall:
            typography.displaySmall?.copyWith(fontWeight: FontWeight.w800),
        headlineSmall:
            typography.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        titleLarge:
            typography.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium:
            typography.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: typography.bodyMedium?.copyWith(height: 1.55),
        bodySmall:
            typography.bodySmall?.copyWith(color: subtitleGrey, height: 1.5),
        labelLarge:
            typography.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _darkScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: typography.titleLarge?.copyWith(
          color: _darkScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.22),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.35),
        selectionHandleColor: primaryColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: typography.bodyMedium?.copyWith(color: inputHint),
        labelStyle: typography.bodyMedium?.copyWith(color: inputHint),
        floatingLabelStyle: typography.bodyMedium?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w700,
        ),
        helperStyle: typography.bodySmall?.copyWith(color: inputHint),
        errorStyle: typography.bodySmall?.copyWith(
          color: dangerColor,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: inputHint,
        suffixIconColor: inputHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: inputBorder),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: inputBorder.withValues(alpha: 0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dangerColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dangerColor, width: 2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        textStyle: typography.bodyMedium?.copyWith(color: inputText),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(cardBg),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
        textStyle: typography.bodyMedium?.copyWith(color: inputText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: typography.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkScheme.onSurface,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: typography.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF202B45),
        contentTextStyle: typography.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: typography.titleLarge,
        contentTextStyle: typography.bodyMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF10182B),
        indicatorColor: primaryColor.withValues(alpha: 0.24),
        labelTextStyle: WidgetStatePropertyAll(typography.labelSmall),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: primaryColor),
    );
  }
}
