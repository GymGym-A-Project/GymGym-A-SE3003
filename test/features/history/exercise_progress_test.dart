import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/set_entry.dart';
import 'package:gymgym_a/data/models/workout_session.dart';
import 'package:gymgym_a/features/history/exercise_progress.dart';

WorkoutSession _session(
  String id,
  int day,
  Map<String, List<SetEntry>> sets, {
  bool finished = true,
}) => WorkoutSession(
  id: id,
  routineId: 'push',
  startedAt: DateTime.utc(2026, 11, day, 18),
  finishedAt: finished ? DateTime.utc(2026, 11, day, 19) : null,
  exercises: [
    for (final MapEntry(:key, :value) in sets.entries)
      WorkoutExercise(exerciseId: key, sets: value),
  ],
);

SetEntry _set(double weightKg, int reps) =>
    SetEntry(weightKg: weightKg, reps: reps);

void main() {
  group('exerciseProgress', () {
    test('reports max weight, best set, volume and set count per date', () {
      final entries = exerciseProgress([
        _session('w1', 3, {
          'bench': [_set(60, 8), _set(70, 5), _set(65, 6)],
          'row': [_set(50, 10)],
        }),
      ], 'bench');

      final entry = entries.single;
      expect(entry.sessionId, 'w1');
      expect(entry.date, DateTime.utc(2026, 11, 3, 18));
      expect(entry.maxWeightKg, 70);
      expect(entry.bestSet.weightKg, 70);
      expect(entry.bestSet.reps, 5);
      expect(entry.totalVolume, 60 * 8 + 70 * 5 + 65 * 6);
      expect(entry.setCount, 3);
    });

    test('orders entries newest first, whatever the input order', () {
      final entries = exerciseProgress([
        _session('a', 1, {
          'bench': [_set(60, 8)],
        }),
        _session('c', 9, {
          'bench': [_set(70, 8)],
        }),
        _session('b', 5, {
          'bench': [_set(65, 8)],
        }),
      ], 'bench');

      expect(entries.map((e) => e.sessionId), ['c', 'b', 'a']);
      expect(entries.map((e) => e.maxWeightKg), [70, 65, 60]);
    });

    test('more reps win between sets of the same weight', () {
      final entry = exerciseProgress([
        _session('w1', 1, {
          'bench': [_set(80, 3), _set(80, 5), _set(80, 4)],
        }),
      ], 'bench').single;

      expect(entry.bestSet.reps, 5);
    });

    test('a bodyweight exercise reports its longest set', () {
      final entry = exerciseProgress([
        _session('w1', 1, {
          'pullup': [_set(0, 8), _set(0, 12), _set(0, 10)],
        }),
      ], 'pullup').single;

      expect(entry.maxWeightKg, 0);
      expect(entry.bestSet.reps, 12);
      expect(entry.totalVolume, 0);
    });

    test('skips unfinished sessions and sessions without the exercise', () {
      final entries = exerciseProgress([
        _session('done', 1, {
          'bench': [_set(60, 8)],
        }),
        _session('running', 2, {
          'bench': [_set(90, 1)],
        }, finished: false),
        _session('legs', 3, {
          'squat': [_set(100, 5)],
        }),
        _session('empty', 4, {'bench': []}),
      ], 'bench');

      expect(entries.map((e) => e.sessionId), ['done']);
    });

    test('is empty for an exercise that was never performed', () {
      expect(exerciseProgress([], 'bench'), isEmpty);
    });
  });

  group('performedExerciseIds', () {
    test('lists each exercise once, most recently performed first', () {
      final ids = performedExerciseIds([
        _session('old', 1, {
          'bench': [_set(60, 8)],
          'row': [_set(50, 10)],
        }),
        _session('new', 8, {
          'squat': [_set(100, 5)],
          'bench': [_set(62.5, 8)],
        }),
      ]);

      expect(ids, ['squat', 'bench', 'row']);
    });

    test('ignores unfinished sessions and exercises without sets', () {
      final ids = performedExerciseIds([
        _session('done', 1, {
          'bench': [_set(60, 8)],
          'skipped': [],
        }),
        _session('running', 2, {
          'squat': [_set(100, 5)],
        }, finished: false),
      ]);

      expect(ids, ['bench']);
    });
  });
}
