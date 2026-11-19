import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/theme/app_text.dart';

void main() {
  test('numbers in the display style use tabular figures', () {
    expect(AppText.display.fontFeatures, [const FontFeature.tabularFigures()]);
  });

  test('every text theme style uses Manrope and the given colours', () {
    const text = Color(0xFF111111);
    const muted = Color(0xFF777777);
    final theme = AppText.textTheme(text, muted);
    final styles = [
      theme.displaySmall,
      theme.headlineSmall,
      theme.titleMedium,
      theme.bodyMedium,
      theme.bodySmall,
      theme.labelSmall,
    ];
    for (final style in styles) {
      expect(style!.fontFamily, AppText.family);
    }
    expect(theme.bodyMedium!.color, text);
    expect(theme.bodySmall!.color, muted);
    expect(theme.headlineSmall!.fontWeight, FontWeight.w800);
  });
}
