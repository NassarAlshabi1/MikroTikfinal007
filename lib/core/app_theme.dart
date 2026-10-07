import 'package:flutter/material.dart';

/// لوحة ألوان **MikroNet** الداكنة (النسخة المعتمدة).
///
/// مستوحاة من تصميم التطبيق المعتمد: خلفية كحلية داكنة، بطاقات أغمق قليلًا
/// بحدود خفيفة، وأزرق ساطع للعناصر النشطة.
class AppColors {
  const AppColors._();

  /// خلفية الصفحات.
  static const Color page = Color(0xFF0B1220);

  /// خلفية البطاقات والنوافذ.
  static const Color card = Color(0xFF16213A);

  /// خلفية الحقول والعناصر الناعمة (شرائح غير مختارة).
  static const Color soft = Color(0xFF1B2740);

  /// حدود وفواصل.
  static const Color border = Color(0xFF243352);

  /// النص الأساسي.
  static const Color text = Color(0xFFE8EEF9);

  /// النص الثانوي.
  static const Color textMuted = Color(0xFF94A3B8);

  /// الأزرق الساطع (الأزرار والعناصر النشطة).
  static const Color primary = Color(0xFF3B82F6);

  /// تدرّج الرؤوس والبطاقات المميّزة.
  static const List<Color> headerGradient = [Color(0xFF0F172A), Color(0xFF1E3A8A)];

  /// ألوان الحالات.
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);
  static const Color purple = Color(0xFF8B5CF6);

  /// ألوان تكامل Telegram.
  static const Color telegram = Color(0xFF229ED9);
}

/// ثيم التطبيق الداكن — يُستخدم في كل الشاشات.
class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      // الخط المعتمد في كل التطبيق (طلب 16)
      fontFamily: 'Cairo',
      fontFamilyFallback: const ['Cairo'],
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primary,
      surface: AppColors.card,
      onSurface: AppColors.text,
      error: AppColors.danger,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.page,
      canvasColor: AppColors.page,
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      shadowColor: Colors.black.withOpacity(0.4),

      // النصوص: كل ما لا يحدد لونًا صريحًا يصبح فاتحًا مقروءًا
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),

      dialogTheme: const DialogTheme(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
      ),

      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
      ),

      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.card),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.soft,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: TextStyle(color: AppColors.text),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.soft,
      ),

      listTileTheme: const ListTileThemeData(
        textColor: AppColors.text,
        iconColor: AppColors.textMuted,
      ),

      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.soft,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
