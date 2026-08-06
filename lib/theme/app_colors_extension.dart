import 'package:flutter/material.dart';

// ============================================================
//  AppColorsExtension — موسّع لنظام الثيم v2
//
//  يوفّر كل الـ semantic tokens التي يحتاجها التطبيق.
//  الاستخدام:
//    Theme.of(context).appColors.primary
//    Theme.of(context).appColors.successContainer
//    Theme.of(context).appColors.cardInteractive
//
//  التصميم:
//  - كل عائلة لونية لها: base + on + container + onContainer
//  - السطوح متعددة المستويات: background, surface, surfaceVariant,
//    card, cardInteractive, cardHover
//  - النصوص: textPrimary, textSecondary, textTertiary, textDisabled
//  - الحدود: outline (قوية), outlineVariant (ناعمة)
// ============================================================

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  AppColorsExtension({
    // Brand
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    // Semantic
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    // Surfaces (layered)
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.card,
    required this.onCard,
    required this.cardInteractive,
    required this.cardHover,
    required this.onCardInteractive,
    // Borders
    required this.outline,
    required this.outlineVariant,
    // Inputs
    required this.inputBackground,
    required this.inputFocusedBorder,
    // Text hierarchy
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    // Misc
    required this.muted,
    required this.scrim,
    required this.shadow,
  });

  // ─── Brand ───
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;

  // ─── Semantic ───
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  // ─── Surfaces (layered) ───
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color card;
  final Color onCard;
  final Color cardInteractive;
  final Color cardHover;
  final Color onCardInteractive;

  // ─── Borders ───
  final Color outline;
  final Color outlineVariant;

  // ─── Inputs ───
  final Color inputBackground;
  final Color inputFocusedBorder;

  // ─── Text hierarchy ───
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  // ─── Misc ───
  final Color muted;
  final Color scrim;
  final Color shadow;

  // ─── Convenience getters (للأسماء القديمة) ───
  /// لون الحدود = outline
  Color get border => outline;

  /// شريط التمرير الناعم
  Color get scrollbarTrack => surfaceVariant;

  Color get scrollbarThumb => outline;

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? card,
    Color? onCard,
    Color? cardInteractive,
    Color? cardHover,
    Color? onCardInteractive,
    Color? outline,
    Color? outlineVariant,
    Color? inputBackground,
    Color? inputFocusedBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? muted,
    Color? scrim,
    Color? shadow,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      card: card ?? this.card,
      onCard: onCard ?? this.onCard,
      cardInteractive: cardInteractive ?? this.cardInteractive,
      cardHover: cardHover ?? this.cardHover,
      onCardInteractive: onCardInteractive ?? this.onCardInteractive,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      inputBackground: inputBackground ?? this.inputBackground,
      inputFocusedBorder: inputFocusedBorder ?? this.inputFocusedBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      muted: muted ?? this.muted,
      scrim: scrim ?? this.scrim,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant AppColorsExtension? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;

    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer:
          Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      secondaryContainer:
          Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondaryContainer:
          Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      onAccentContainer:
          Color.lerp(onAccentContainer, other.onAccentContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer:
          Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      card: Color.lerp(card, other.card, t)!,
      onCard: Color.lerp(onCard, other.onCard, t)!,
      cardInteractive: Color.lerp(cardInteractive, other.cardInteractive, t)!,
      cardHover: Color.lerp(cardHover, other.cardHover, t)!,
      onCardInteractive:
          Color.lerp(onCardInteractive, other.onCardInteractive, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputFocusedBorder:
          Color.lerp(inputFocusedBorder, other.inputFocusedBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
