import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/set_entry.dart';
import 'package:gymgym_a/data/models/workout_session.dart';
import 'package:gymgym_a/data/repositories/fake_workout_session_repository.dart';
import 'package:gymgym_a/data/repositories/workout_session_providers.dart';
import 'package:gymgym_a/features/logger/ghost_values.dart';
import 'package:gymgym_a/features/logger/active_workout.dart';
import 'package:gymgym_a/features/logger/workout_draft_store.dart';

import '../../helpers/memory_workout_draft_store.dart';
import 'active_workout_test.dart' show routine;

WorkoutSession previousSession(
  String id,
  DateTime start,
  Map<String, List<SetEntry>> exercises, {
  DateTime? finish,
  bool completed = true,
}) => WorkoutSession(
  id: id,
  routineId: 'push',
  startedAt: start,
  finishedAt: completed ? finish ?? start.add(const Duration(hours: 1)) : null,
  exercises: [
    for (final e in exercises.entries)
      WorkoutExercise(exerciseId: e.key, sets: e.value),
  ],
);

void main() {
  final now = DateTime.utc(2026, 11, 19, 12);
  SetEntry set(double kg, int reps) => SetEntry(weightKg: kg, reps: reps);

  test('selects the latest completion per exercise, preserving set order', () {
    final result = previousSets([
      previousSession('older', now.subtract(const Duration(days: 3)), {
        '1': [set(50, 8)],
        '2': [set(40, 10)],
      }),
      previousSession('newer', now.subtract(const Duration(days: 1)), {
        '1': [set(60, 8), set(62.5, 6)],
      }),
    ], before: now);
    expect(result['1']!.map((s) => s.weightKg), [60, 62.5]);
    expect(result['2']!.single.weightKg, 40);
  });

  test('unfinished and future completions cannot become hints', () {
    final result = previousSets([
      previousSession('pending', now.subtract(const Duration(hours: 2)), {
        '1': [set(100, 1)],
      }, completed: false),
      previousSession('future', now, {
        '1': [set(120, 1)],
      }),
      previousSession('completed', now.subtract(const Duration(days: 1)), {
        '1': [set(60, 8)],
      }),
    ], before: now);
    expect(result['1']!.single.weightKg, 60);
  });

  test('last means finish time, with stable start/id tie breaks', () {
    final result = previousSets([
      previousSession('b', now.subtract(const Duration(hours: 4)), {
        '1': [set(60, 8)],
      }, finish: now),
      previousSession('a', now.subtract(const Duration(hours: 4)), {
        '1': [set(65, 6)],
      }, finish: now),
      previousSession('later-start', now.subtract(const Duration(hours: 2)), {
        '1': [set(70, 4)],
      }, finish: now.subtract(const Duration(minutes: 1))),
    ], before: now);
    expect(result['1']!.single.weightKg, 65);
  });

  test(
    'bodyweight zero, fractional kg and empty previous sets are handled',
    () {
      final result = previousSets([
        previousSession('empty', now.subtract(const Duration(hours: 2)), {
          '1': [],
        }),
        previousSession('valid', now.subtract(const Duration(days: 1)), {
          '1': [set(0, 12)],
          '2': [set(12.5, 8)],
        }),
      ], before: now);
      expect(ghostWeight(result['1']!.single.weightKg), '0');
      expect(ghostWeight(result['2']!.single.weightKg), '12.5');
      expect(previousSets([], before: now), isEmpty);
      expect(() => result.clear(), throwsUnsupportedError);
      expect(() => result['1']!.clear(), throwsUnsupportedError);
    },
  );

  test('60 cached sessions load hints under 200 ms and do not fill the draft', () async {
    final repository = FakeWorkoutSessionRepository(
      sessions: [
        for (var i = 0; i < 60; i++)
          previousSession('$i', now.subtract(Duration(days: 60 - i)), {
            '1': [set(20 + i.toDouble(), 8)],
          }),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        workoutSessionRepositoryProvider.overrideWithValue(repository),
        workoutDraftStoreProvider.overrideWithValue(MemoryWorkoutDraftStore()),
      ],
    );
    addTearDown(container.dispose);
    final keepAlive = container.listen(ghostValuesProvider(now), (_, _) {});
    addTearDown(keepAlive.close);
    final stopwatch = Stopwatch()..start();
    final hints = await container.read(ghostValuesProvider(now).future);
    stopwatch.stop();
    expect(hints.sets['1']!.single.weightKg, 79);
    expect(stopwatch.elapsedMilliseconds, lessThan(200));
    // This is a VM regression guard, not a physical/profile device claim.
    // Native cache timing is covered separately by the Android acceptance test.
    debugPrint(
      '60-session VM ghost lookup: ${stopwatch.elapsedMicroseconds} us',
    );
    await container.read(activeWorkoutProvider('alice').future);
    final active = container.read(activeWorkoutProvider('alice').notifier);
    await active.start(routine(sets: 1));
    final draft = container.read(activeWorkoutProvider('alice')).value!;
    expect(draft.exercises.single.sets.single.weight, '');
    expect(draft.exercises.single.sets.single.reps, '');
    await expectLater(active.finish(repository), throwsStateError);
    await active.updateSet('1', '0', weight: '80', reps: '8');
    final saveTime = Stopwatch()..start();
    await active.finish(repository);
    saveTime.stop();
    expect(saveTime.elapsedMilliseconds, lessThan(1000));
    expect(
      (await repository.getCached()).where((s) => s.finishedAt != null),
      hasLength(61),
    );
  });
}
