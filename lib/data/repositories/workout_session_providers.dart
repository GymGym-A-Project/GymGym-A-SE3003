import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../models/workout_session.dart';
import 'firestore_workout_session_repository.dart';
import 'routine_providers.dart';
import 'workout_session_repository.dart';

/// Workout sessions of the signed-in user, or null while nobody is signed in.
///
/// Follows the same rule as the router: an auth error counts as signed out.
final workoutSessionRepositoryProvider = Provider<WorkoutSessionRepository?>((
  ref,
) {
  final uid = ref.watch(
    authStateProvider.select((auth) => auth.hasError ? null : auth.value?.id),
  );
  if (uid == null) return null;
  final repository = FirestoreWorkoutSessionRepository(
    ref.watch(firestoreProvider),
    uid,
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final workoutWriteFailuresProvider = StreamProvider<WorkoutWriteFailure>(
  (ref) =>
      ref.watch(workoutSessionRepositoryProvider)?.writeFailures ??
      const Stream.empty(),
);

/// Live session list of the signed-in user, newest first, including sessions
/// that are still in progress.
///
/// Stays loading while nobody is signed in; the router leaves these screens.
final workoutSessionListProvider = StreamProvider<List<WorkoutSession>>((ref) {
  final repository = ref.watch(workoutSessionRepositoryProvider);
  return repository?.watch() ?? const Stream.empty();
});

/// Completed sessions only, newest first. A session without `finishedAt` is
/// still being logged and does not belong in the history.
final workoutHistoryProvider = Provider<AsyncValue<List<WorkoutSession>>>(
  (ref) => ref
      .watch(workoutSessionListProvider)
      .whenData(
        (sessions) => List.unmodifiable(
          sessions.where((session) => session.finishedAt != null),
        ),
      ),
);
