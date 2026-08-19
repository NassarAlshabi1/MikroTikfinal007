import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mikrotik_manager/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  group('AppTheme.darkTheme', () {
    test('keeps input fields readable and clearly stateful', () {
      final theme = AppTheme.darkTheme;
      final input = theme.inputDecorationTheme;
      final enabledBorder = input.enabledBorder! as OutlineInputBorder;
      final focusedBorder = input.focusedBorder! as OutlineInputBorder;
      final errorBorder = input.errorBorder! as OutlineInputBorder;

      expect(input.filled, isTrue);
      expect(input.fillColor, AppTheme.inputBg);
      expect(input.hintStyle?.color, AppTheme.inputHint);
      expect(input.labelStyle?.color, AppTheme.inputHint);
      expect(input.floatingLabelStyle?.color, AppTheme.primaryColor);
      expect(enabledBorder.borderSide.color, AppTheme.inputBorder);
      expect(focusedBorder.borderSide.color, AppTheme.primaryColor);
      expect(focusedBorder.borderSide.width, 2);
      expect(errorBorder.borderSide.color, AppTheme.dangerColor);
      expect(theme.popupMenuTheme.color, AppTheme.cardBg);
      expect(theme.textSelectionTheme.cursorColor, AppTheme.primaryColor);
    });
  });
}
