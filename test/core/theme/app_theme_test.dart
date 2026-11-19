import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/theme/app_theme.dart';
import 'package:gymgym_a/core/theme/gym_colors.dart';

void main() {
  test('the app opens in the dark theme', () {
    expect(AppTheme.mode, ThemeMode.dark);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.brightness, Brightness.light);
  });

  test('themes carry their colour tokens and use the Kor accent', () {
    expect(AppTheme.dark.extension<GymColors>(), same(GymColors.dark));
    expect(AppTheme.light.extension<GymColors>(), same(GymColors.light));
    expect(AppTheme.dark.colorScheme.primary, GymColors.dark.kor);
    expect(AppTheme.dark.scaffoldBackgroundColor, GymColors.dark.bg);
  });

  test('cards use a border instead of a shadow', () {
    final card = AppTheme.dark.cardTheme;
    expect(card.elevation, 0);
    final shape = card.shape! as RoundedRectangleBorder;
    expect(shape.side.color, GymColors.dark.border);
  });
}
