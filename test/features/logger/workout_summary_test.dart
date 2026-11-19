import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/set_entry.dart';
import 'package:gymgym_a/features/logger/workout_summary.dart';

import 'ghost_values_test.dart' show previousSession;

void main() {
  testWidgets(
    'summary derives volume, set count, duration and exercise count',
    (tester) async {
      final session = previousSession(
        'finished',
        DateTime.utc(2026, 11, 19, 10),
        {
          '1': [
            SetEntry(weightKg: 60, reps: 8),
            SetEntry(weightKg: 62.5, reps: 6),
          ],
          '2': [SetEntry(weightKg: 0, reps: 12)],
        },
        finish: DateTime.utc(2026, 11, 19, 11, 5),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WorkoutSummary(session: session)),
        ),
      );
      expect(find.text('855 kg'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1 h 05 min'), findsOneWidget);
    },
  );
}
