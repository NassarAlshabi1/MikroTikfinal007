import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/theme/professional_theme.dart';

void main() {
  test('الثيم الداكن يستخدم خلفية عميقة وسطحاً متدرجاً', () {
    final theme = ProfessionalTheme.dark;

    expect(theme.scaffoldBackgroundColor, ProfessionalColors.darkBackground);
    expect(theme.colorScheme.surface, ProfessionalColors.darkSurface);
    expect(theme.colorScheme.surfaceContainerHighest,
        ProfessionalColors.darkSurfaceVariant);
    expect(theme.cardTheme.color, ProfessionalColors.darkCard);
  });

  test('الحقول والقوائم والنوافذ تتبع لوحة الثيم الداكن', () {
    final theme = ProfessionalTheme.dark;

    expect(theme.inputDecorationTheme.fillColor,
        ProfessionalColors.darkSurfaceVariant);
    expect(theme.inputDecorationTheme.labelStyle?.color,
        ProfessionalColors.darkTextSecondary);
    expect(theme.popupMenuTheme.color, ProfessionalColors.darkSurfaceVariant);
    expect(theme.dialogTheme.backgroundColor, ProfessionalColors.darkSurface);
    expect(
        theme.bottomSheetTheme.backgroundColor, ProfessionalColors.darkSurface);
  });

  test('الخط العربي Tajawal مضبوط على مستوى ThemeData', () {
    final theme = ProfessionalTheme.dark;

    expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Tajawal');
    expect(theme.textTheme.bodyLarge?.fontFamily, 'Tajawal');
  });
}
