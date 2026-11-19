import 'package:flutter/material.dart';

import 'app_text.dart';
import 'gaps.dart';
import 'gym_colors.dart';

/// Material themes built from [GymColors]. Dark is the default; light is
/// supported. Cards use a 1 px border instead of a shadow.
abstract final class AppTheme {
  static final dark = _build(GymColors.dark, Brightness.dark);
  static final light = _build(GymColors.light, Brightness.light);

  /// The app opens in the dark theme (design system default).
  static const mode = ThemeMode.dark;

  static ThemeData _build(GymColors c, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(seedColor: c.kor, brightness: brightness).copyWith(
          primary: c.kor,
          onPrimary: c.onKor,
          secondary: c.kor,
          onSecondary: c.onKor,
          surface: c.bg,
          onSurface: c.text,
          onSurfaceVariant: c.textMuted,
          surfaceContainerLowest: c.bg,
          surfaceContainerLow: c.surface,
          surfaceContainer: c.surface,
          surfaceContainerHigh: c.surface2,
          surfaceContainerHighest: c.surface2,
          outline: c.border,
          outlineVariant: c.border,
          error: c.danger,
          onError: c.onKor,
          tertiary: c.success,
        );
    final text = AppText.textTheme(c.text, c.textMuted);
    final buttonText = AppText.body.copyWith(fontWeight: FontWeight.w700);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    final pill = RoundedRectangleBorder(borderRadius: Radii.pillBorder);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppText.family,
      textTheme: text,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.border,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.title.copyWith(color: c.text),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: Gap.s),
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardBorder,
          side: BorderSide(color: c.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface2,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.m,
          vertical: Gap.m,
        ),
        labelStyle: AppText.label.copyWith(color: c.textMuted),
        floatingLabelStyle: AppText.label.copyWith(color: c.textMuted),
        hintStyle: AppText.body.copyWith(color: c.textMuted),
        border: OutlineInputBorder(
          borderRadius: Radii.inputBorder,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.inputBorder,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.inputBorder,
          borderSide: BorderSide(color: c.kor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.inputBorder,
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.inputBorder,
          borderSide: BorderSide(color: c.danger, width: 1.5),
        ),
        errorStyle: AppText.body.copyWith(fontSize: 12, color: c.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.kor,
          foregroundColor: c.onKor,
          disabledBackgroundColor: c.surface2,
          disabledForegroundColor: c.ghost,
          minimumSize: const Size(64, Gap.touch),
          padding: buttonPadding,
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size(64, Gap.touch),
          padding: buttonPadding,
          side: BorderSide(color: c.border),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.kor,
          minimumSize: const Size(48, Gap.touch),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textMuted,
          minimumSize: const Size.square(Gap.touch),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.kor,
        foregroundColor: c.onKor,
        elevation: 4,
        shape: pill,
        extendedTextStyle: buttonText,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.kor,
        disabledColor: c.surface2,
        side: BorderSide(color: c.border),
        shape: pill,
        showCheckmark: false,
        labelStyle: AppText.body.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.text,
        ),
        secondaryLabelStyle: AppText.body.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.onKor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textMuted,
        textColor: c.text,
        titleTextStyle: AppText.headline.copyWith(fontSize: 15, color: c.text),
        subtitleTextStyle: AppText.body.copyWith(
          fontSize: 13,
          color: c.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.screen),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: c.kor,
        collapsedIconColor: c.textMuted,
        textColor: c.text,
        collapsedTextColor: c.text,
        shape: const Border(),
        collapsedShape: const Border(),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.kor,
        unselectedLabelColor: c.textMuted,
        indicatorColor: c.kor,
        dividerColor: c.border,
        labelStyle: AppText.body.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppText.body,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.kor.withValues(alpha: 0.18),
        elevation: 0,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? c.kor : c.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppText.label.copyWith(
            letterSpacing: 0.2,
            color: states.contains(WidgetState.selected) ? c.kor : c.textMuted,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: Radii.sheetBorder),
        titleTextStyle: AppText.headline.copyWith(color: c.text),
        contentTextStyle: AppText.body.copyWith(color: c.textMuted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surface2,
        contentTextStyle: AppText.body.copyWith(color: c.text),
        actionTextColor: c.kor,
        shape: RoundedRectangleBorder(borderRadius: Radii.inputBorder),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.kor),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.success : c.surface2,
        ),
      ),
    );
  }
}
