import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/core/router.dart';
import 'package:gymgym_a/data/models/routine.dart';
import 'package:gymgym_a/data/models/routine_item.dart';
import 'package:gymgym_a/data/models/set_entry.dart';
import 'package:gymgym_a/data/models/workout_session.dart';
import 'package:gymgym_a/data/repositories/fake_routine_repository.dart';
import 'package:gymgym_a/data/repositories/fake_workout_session_repository.dart';
import 'package:gymgym_a/data/repositories/workout_session_providers.dart';
import 'package:gymgym_a/features/history/exercise_history_screen.dart';

import '../../helpers/routine_app.dart';

// Fake exercise ids: 1 Bench Press, 2 Lat Pulldown, 3 Barbell Squat.
WorkoutSession _session(
  String id,
  int day,
  Map<String, List<SetEntry>> sets, {
  String routineId = 'push',
  bool finished = true,
}) => WorkoutSession(
  id: id,
  routineId: routineId,
  startedAt: DateTime(2026, 11, day, 18),
  finishedAt: finished ? DateTime(2026, 11, day, 19, 5) : null,
  exercises: [
    for (final MapEntry(:key, :value) in sets.entries)
      WorkoutExercise(exerciseId: key, sets: value),
  ],
);

SetEntry _set(double weightKg, int reps) =>
    SetEntry(weightKg: weightKg, reps: reps);

final _sessions = [
  _session('w1', 3, {
    '1': [_set(60, 8), _set(62.5, 6)],
    '2': [_set(50, 10)],
  }),
  _session('w2', 10, {
    '1': [_set(65, 5)],
    '3': [_set(100, 5), _set(100, 5)],
  }, routineId: 'deleted'),
  _session('running', 12, {
    '1': [_set(90, 1)],
  }, finished: false),
];

Future<void> _pumpHistory(
  WidgetTester tester, {
  List<WorkoutSession> sessions = const [],
  String location = AppRoutes.history,
}) => pumpRoutineApp(
  tester,
  location: location,
  repository: FakeRoutineRepository(
    routines: [
      Routine(
        id: 'push',
        name: 'Push day',
        order: 0,
        items: [RoutineItem(exerciseId: '1', targetSets: 3)],
        source: 'custom',
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    ],
  ),
  overrides: [
    workoutSessionRepositoryProvider.overrideWithValue(
      FakeWorkoutSessionRepository(sessions: sessions),
    ),
  ],
);

void main() {
  testWidgets('shows an empty state without completed workouts', (
    tester,
  ) async {
    await _pumpHistory(
      tester,
      sessions: [
        _session('running', 12, {
          '1': [_set(90, 1)],
        }, finished: false),
      ],
    );

    expect(find.text('No completed workouts yet'), findsOneWidget);
  });

  testWidgets('lists completed sessions newest first, without unfinished '
      'ones', (tester) async {
    await _pumpHistory(tester, sessions: _sessions);

    expect(find.text('12 Nov 2026'), findsNothing);
    final newer = tester.getTopLeft(find.text('10 Nov 2026'));
    final older = tester.getTopLeft(find.text('3 Nov 2026'));
    expect(newer.dy, lessThan(older.dy));

    expect(find.text('Push day · 2 exercises · 1,355 kg'), findsOneWidget);
    // The routine of w2 was deleted, so a generic title stands in.
    expect(find.text('Workout · 2 exercises · 1,325 kg'), findsOneWidget);
  });

  testWidgets('tapping a session shows its exercises, sets and volume', (
    tester,
  ) async {
    await _pumpHistory(tester, sessions: _sessions);
    expect(find.text('Set 1: 60 kg × 8'), findsNothing);

    await tester.tap(find.text('3 Nov 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Set 1: 60 kg × 8'), findsOneWidget);
    expect(find.text('Set 2: 62.5 kg × 6'), findsOneWidget);
    expect(find.text('Volume: 855 kg'), findsOneWidget);
    expect(find.text('Lat Pulldown'), findsOneWidget);
    expect(find.text('Set 1: 50 kg × 10'), findsOneWidget);
    expect(find.text('Total volume: 1,355 kg'), findsOneWidget);
    expect(find.text('Duration: 1 h 05 min'), findsOneWidget);
  });

  testWidgets('a session saved later appears without a restart', (
    tester,
  ) async {
    final repository = FakeWorkoutSessionRepository();
    await pumpRoutineApp(
      tester,
      location: AppRoutes.history,
      overrides: [
        workoutSessionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    expect(find.text('No completed workouts yet'), findsOneWidget);

    await repository.save(
      _session('w1', 3, {
        '1': [_set(60, 8)],
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 Nov 2026'), findsOneWidget);
  });

  testWidgets('the by-exercise tab lists performed exercises and opens one', (
    tester,
  ) async {
    await _pumpHistory(tester, sessions: _sessions);

    await tester.tap(find.text('By exercise'));
    await tester.pumpAndSettle();

    final bench = tester.getTopLeft(find.text('Bench Press'));
    final squat = tester.getTopLeft(find.text('Barbell Squat'));
    final pulldown = tester.getTopLeft(find.text('Lat Pulldown'));
    // Most recently performed first; the unfinished session does not count.
    expect(bench.dy, lessThan(squat.dy));
    expect(squat.dy, lessThan(pulldown.dy));
    expect(find.text('2 sessions'), findsOneWidget);

    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    expect(find.byType(ExerciseHistoryScreen), findsOneWidget);
  });

  testWidgets('exercise history shows date-by-date max weight, best set and '
      'volume', (tester) async {
    await _pumpHistory(
      tester,
      sessions: _sessions,
      location: AppRoutes.exerciseHistory('1'),
    );

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Bench Press'),
      ),
      findsOneWidget,
    );
    expect(find.text('Top weight: 65 kg'), findsOneWidget);
    expect(find.text('2 sessions'), findsOneWidget);

    final newer = find.byKey(const ValueKey('entry-w2'));
    final older = find.byKey(const ValueKey('entry-w1'));
    expect(tester.getTopLeft(newer).dy, lessThan(tester.getTopLeft(older).dy));
    expect(
      find.descendant(
        of: newer,
        matching: find.text('Best set 65 kg × 5 · 1 set · Volume 325 kg'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: older,
        matching: find.text('Best set 62.5 kg × 6 · 2 sets · Volume 855 kg'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: older, matching: find.text('62.5 kg')),
      findsOneWidget,
    );
    expect(find.text('90 kg'), findsNothing);
  });

  testWidgets('exercise history of an unperformed exercise is empty', (
    tester,
  ) async {
    await _pumpHistory(
      tester,
      sessions: _sessions,
      location: AppRoutes.exerciseHistory('99'),
    );

    expect(find.text('No sets logged yet'), findsOneWidget);
    expect(find.text('Exercise history'), findsOneWidget);
  });
}
