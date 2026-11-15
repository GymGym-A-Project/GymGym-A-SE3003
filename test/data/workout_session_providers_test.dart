import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/data/auth/auth_providers.dart';
import 'package:gymgym_a/data/auth/fake_auth_repository.dart';
import 'package:gymgym_a/data/models/set_entry.dart';
import 'package:gymgym_a/data/models/workout_session.dart';
import 'package:gymgym_a/data/repositories/fake_workout_session_repository.dart';
import 'package:gymgym_a/data/repositories/routine_providers.dart';
import 'package:gymgym_a/data/repositories/workout_session_providers.dart';

WorkoutSession _session(String id, int day, {bool finished = true}) =>
    WorkoutSession(
      id: id,
      routineId: 'push',
      startedAt: DateTime.utc(2026, 11, day, 18),
      finishedAt: finished ? DateTime.utc(2026, 11, day, 19) : null,
      exercises: [
        WorkoutExercise(
          exerciseId: '1',
          sets: [SetEntry(weightKg: 60, reps: 8)],
        ),
      ],
    );

void main() {
  test('there is no repository while nobody is signed in', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.listen(
      workoutSessionRepositoryProvider,
      (_, _) {},
    );
    await pumpEventQueue();

    expect(repository.read(), isNull);
  });

  test('the signed-in user gets a repository', () async {
    final auth = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      ],
    );
    addTearDown(container.dispose);
    final repository = container.listen(
      workoutSessionRepositoryProvider,
      (_, _) {},
    );

    await auth.register(email: 'a@example.com', password: 'secret123');
    await pumpEventQueue();

    expect(repository.read(), isNotNull);
  });

  test('history keeps only finished sessions, newest first', () async {
    final container = ProviderContainer(
      overrides: [
        workoutSessionRepositoryProvider.overrideWithValue(
          FakeWorkoutSessionRepository(
            sessions: [
              _session('old', 1),
              _session('running', 12, finished: false),
              _session('new', 10),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(workoutHistoryProvider, (_, _) {});
    await pumpEventQueue();

    final history = container.read(workoutHistoryProvider).requireValue;
    expect(history.map((session) => session.id), ['new', 'old']);
  });
}
