import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/set_entry.dart';
import 'package:gymgym_a/data/repositories/fake_workout_session_repository.dart';

import 'ghost_values_test.dart' show previousSession;
import 'logger_screen_test.dart' show pumpLogger;

TextField input(WidgetTester tester, String field) => tester.widget<TextField>(
  find.descendant(
    of: find.byKey(ValueKey(field)),
    matching: find.byType(TextField),
  ),
);

void main() {
  testWidgets('Complete set accepts hints and preserves an edited value', (
    tester,
  ) async {
    final repo = FakeWorkoutSessionRepository(
      sessions: [
        previousSession('last', DateTime.utc(2026, 1), {
          '1': [SetEntry(weightKg: 62.5, reps: 8)],
        }),
      ],
    );
    await pumpLogger(tester, sessions: repo);
    await tester.tap(find.byKey(const ValueKey('start-workout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('complete-1-0')));
    await tester.pumpAndSettle();
    expect(input(tester, 'weight-1-0').controller!.text, '62.5');
    expect(input(tester, 'reps-1-0').controller!.text, '8');
    await tester.enterText(find.byKey(const ValueKey('weight-1-0')), '70');
    await tester.enterText(find.byKey(const ValueKey('reps-1-0')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('complete-1-0')));
    await tester.pumpAndSettle();
    expect(input(tester, 'weight-1-0').controller!.text, '70');
    expect(input(tester, 'reps-1-0').controller!.text, '8');
    await tester.ensureVisible(find.byKey(const ValueKey('finish-workout')));
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle();
    expect(find.text('560 kg'), findsOneWidget);
  });
  testWidgets('previous values are hints; blank inputs still fail validation', (
    tester,
  ) async {
    final repo = FakeWorkoutSessionRepository(
      sessions: [
        previousSession('last', DateTime.utc(2026, 1), {
          '1': [SetEntry(weightKg: 62.5, reps: 8)],
        }),
      ],
    );
    await pumpLogger(tester, sessions: repo);
    await tester.tap(find.byKey(const ValueKey('start-workout')));
    await tester.pumpAndSettle();
    final weight = input(tester, 'weight-1-0');
    expect(weight.controller!.text, '');
    expect(weight.decoration!.hintText, '62.5');
    expect(
      weight.decoration!.floatingLabelBehavior,
      FloatingLabelBehavior.always,
    );
    expect(input(tester, 'reps-1-0').decoration!.hintText, '8');
    await tester.ensureVisible(find.byKey(const ValueKey('finish-workout')));
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle();
    expect(find.text('Enter kg of 0 or more.'), findsOneWidget);
    expect(await repo.getCached(), hasLength(1));
  });

  testWidgets('actual input hides a hint; clearing it does not save the hint', (
    tester,
  ) async {
    final repo = FakeWorkoutSessionRepository(
      sessions: [
        previousSession('last', DateTime.utc(2026, 1), {
          '1': [SetEntry(weightKg: 0, reps: 12)],
        }),
      ],
    );
    await pumpLogger(tester, sessions: repo);
    await tester.tap(find.byKey(const ValueKey('start-workout')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('weight-1-0')), '10');
    await tester.pumpAndSettle();
    expect(input(tester, 'weight-1-0').controller!.text, '10');
    await tester.enterText(find.byKey(const ValueKey('weight-1-0')), '');
    await tester.pumpAndSettle();
    expect(input(tester, 'weight-1-0').controller!.text, '');
    expect(input(tester, 'weight-1-0').decoration!.hintText, '0');
  });

  testWidgets('finish shows totals and a separate action opens History', (
    tester,
  ) async {
    final repo = FakeWorkoutSessionRepository();
    await pumpLogger(tester, sessions: repo);
    await tester.tap(find.byKey(const ValueKey('start-workout')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('weight-1-0')), '60');
    await tester.enterText(find.byKey(const ValueKey('reps-1-0')), '8');
    await tester.ensureVisible(find.byKey(const ValueKey('finish-workout')));
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle();
    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('Total volume'), findsOneWidget);
    expect(find.text('480 kg'), findsOneWidget);
    expect(find.text('Total sets'), findsOneWidget);
    expect(find.text('Exercises'), findsWidgets);
    expect(find.text('Duration'), findsOneWidget);
    await tester.tap(find.text('View history'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Push day'), findsWidgets);
    expect(find.text('Workout complete'), findsNothing);
  });
}
