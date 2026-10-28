import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/models/set_entry.dart';
import 'package:gymgym_a/data/models/workout_session.dart';
import 'package:gymgym_a/data/repositories/fake_workout_session_repository.dart';

WorkoutSession session(
  String id, {
  int day = 1,
  DateTime? finishedAt,
}) => WorkoutSession(
  id: id,
  routineId: 'push',
  startedAt: DateTime.utc(2026, 10, day),
  finishedAt: finishedAt,
  exercises: [
    WorkoutExercise(exerciseId: 'z', sets: [SetEntry(weightKg: 20, reps: 8)]),
    WorkoutExercise(exerciseId: 'a', sets: [SetEntry(weightKg: 0, reps: 10)]),
  ],
);

void main() {
  test('sets accept bodyweight and reject invalid load or reps', () {
    expect(SetEntry(weightKg: 0, reps: 1).volume, 0);
    for (final weight in [-1.0, double.nan, double.infinity]) {
      expect(() => SetEntry(weightKg: weight, reps: 1), throwsArgumentError);
    }
    for (final reps in [0, -1]) {
      expect(() => SetEntry(weightKg: 10, reps: reps), throwsArgumentError);
    }
    expect(SetEntry.fromJson({'weightKg': 20, 'reps': 8}).weightKg, 20.0);
  });

  test(
    'session JSON round-trip retains order, timestamps and derived volume',
    () {
      for (final finishedAt in [null, DateTime.utc(2026, 10, 1, 1)]) {
        final original = session('workout', finishedAt: finishedAt);
        final copy = WorkoutSession.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
        );
        expect(copy.toJson(), original.toJson());
        expect(copy.totalVolume, 160);
        expect(copy.exercises.map((e) => e.exerciseId), ['z', 'a']);
      }
    },
  );

  test('session validates time range and exercise count and ids', () {
    final original = session('workout');
    expect(
      () => session('workout', finishedAt: DateTime.utc(2025)),
      throwsArgumentError,
    );
    for (final count in [0, 16]) {
      expect(
        () => WorkoutSession(
          id: 'w',
          routineId: 'r',
          startedAt: DateTime.utc(2026),
          exercises: List.generate(
            count,
            (i) => WorkoutExercise(exerciseId: '$i', sets: []),
          ),
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => WorkoutSession(
        id: 'w',
        routineId: 'r',
        startedAt: original.startedAt,
        exercises: [original.exercises.first, original.exercises.first],
      ),
      throwsArgumentError,
    );
    expect(
      () => WorkoutExercise(exerciseId: ' ', sets: []),
      throwsArgumentError,
    );
    expect(() => session(' '), throwsArgumentError);
  });

  test('nested lists are defensive copies and immutable', () {
    final sets = [SetEntry(weightKg: 10, reps: 5)];
    final exercises = [WorkoutExercise(exerciseId: 'bench', sets: sets)];
    final workout = WorkoutSession(
      id: 'w',
      routineId: 'r',
      startedAt: DateTime.utc(2026),
      exercises: exercises,
    );
    sets.clear();
    exercises.clear();
    expect(workout.exercises.single.sets, hasLength(1));
    expect(() => workout.exercises.clear(), throwsUnsupportedError);
    expect(() => workout.exercises.single.sets.clear(), throwsUnsupportedError);
  });

  test(
    'fake CRUD, sorting, immutable snapshots and independent scopes',
    () async {
      final repository = FakeWorkoutSessionRepository(
        sessions: [session('b'), session('a')],
      );
      final before = await repository.watch().first;
      expect(before.map((s) => s.id), ['a', 'b']);
      expect(() => before.clear(), throwsUnsupportedError);
      expect(await repository.get('missing'), isNull);
      await repository.save(session('b', day: 2));
      expect((await repository.watch().first).map((s) => s.id), ['b', 'a']);
      expect((await repository.get('b'))!.startedAt.day, 2);
      expect(before.last.startedAt.day, 1);
      expect(await FakeWorkoutSessionRepository().get('b'), isNull);
      await repository.delete('b');
      await repository.delete('missing');
      expect(await repository.get('b'), isNull);
    },
  );

  test(
    'each observer receives current snapshot, save, replace and delete',
    () async {
      final repository = FakeWorkoutSessionRepository();
      final expected = [isEmpty, hasLength(1), hasLength(1), isEmpty];
      final first = expectLater(
        repository.watch().take(4),
        emitsInOrder(expected),
      );
      final second = expectLater(
        repository.watch().take(4),
        emitsInOrder(expected),
      );
      await repository.save(session('a'));
      await repository.save(session('a', day: 2));
      await repository.delete('a');
      await Future.wait([first, second]);
    },
  );
}
