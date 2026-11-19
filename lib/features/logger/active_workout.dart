import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/routine.dart';
import '../../data/repositories/workout_session_repository.dart';
import 'workout_draft.dart';
import 'workout_draft_store.dart';

final activeWorkoutProvider =
    AsyncNotifierProvider.family<ActiveWorkout, WorkoutDraft?, String>(
      ActiveWorkout.new,
    );

/// User-scoped state survives tab changes; the store restores it after restart.
class ActiveWorkout extends AsyncNotifier<WorkoutDraft?> {
  ActiveWorkout(this.uid);
  final String uid;
  Future<void> _pending = Future.value();
  final _random = Random.secure();
  bool _finishing = false;

  /// Await the queued device writes before an explicit lifecycle checkpoint.
  Future<void> flush() => _pending;

  @override
  Future<WorkoutDraft?> build() =>
      ref.watch(workoutDraftStoreProvider).read(uid);

  String _id() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

  Future<void> _save(WorkoutDraft? draft) {
    final store = ref.read(workoutDraftStoreProvider);
    state = AsyncData(draft);
    // Serialize writes so an older keystroke cannot overwrite a newer one.
    final next = _pending.then((_) => store.write(uid, draft));
    _pending = next.catchError((Object _) {});
    return next;
  }

  WorkoutDraft get _editable {
    final draft = state.value;
    if (draft == null || draft.isFinished || _finishing) {
      throw StateError('No editable workout.');
    }
    return draft;
  }

  Future<void> start(Routine routine) async {
    if (state.isLoading) await future;
    if (state.hasError) throw StateError('Reload the saved workout first.');
    if (state.value case final current? when !current.isFinished) {
      throw StateError('Finish or discard your current workout first.');
    }
    await _save(
      WorkoutDraft.fromRoutine(routine, id: _id(), now: DateTime.now().toUtc()),
    );
  }

  Future<void> updateSet(
    String exerciseId,
    String setId, {
    String? weight,
    String? reps,
  }) {
    final draft = _editable;
    return _save(
      draft.copyWith(
        exercises: [
          for (final exercise in draft.exercises)
            if (exercise.exerciseId != exerciseId)
              exercise
            else
              WorkoutExerciseDraft(
                exerciseId: exerciseId,
                sets: [
                  for (final set in exercise.sets)
                    if (set.id != setId)
                      set
                    else
                      WorkoutSetDraft(
                        id: set.id,
                        weight: weight ?? set.weight,
                        reps: reps ?? set.reps,
                      ),
                ],
              ),
        ],
      ),
    );
  }

  Future<void> addSet(String exerciseId) {
    final draft = _editable;
    return _save(
      draft.copyWith(
        exercises: [
          for (final exercise in draft.exercises)
            if (exercise.exerciseId != exerciseId)
              exercise
            else
              WorkoutExerciseDraft(
                exerciseId: exerciseId,
                sets: [
                  ...exercise.sets,
                  WorkoutSetDraft(id: _id()),
                ],
              ),
        ],
      ),
    );
  }

  Future<void> removeSet(String exerciseId, String setId) {
    final draft = _editable;
    return _save(
      draft.copyWith(
        exercises: [
          for (final exercise in draft.exercises)
            if (exercise.exerciseId != exerciseId)
              exercise
            else
              WorkoutExerciseDraft(
                exerciseId: exerciseId,
                sets: [
                  for (final s in exercise.sets)
                    if (s.id != setId) s,
                ],
              ),
        ],
      ),
    );
  }

  Future<void> toggleExercise(String exerciseId) {
    final draft = _editable;
    final exists = draft.exercises.any((e) => e.exerciseId == exerciseId);
    if (exists && draft.exercises.length == 1) {
      throw StateError('Keep at least one exercise.');
    }
    if (!exists && draft.exercises.length == 15) {
      throw StateError('A workout can have at most 15 exercises.');
    }
    return _save(
      draft.copyWith(
        exercises: [
          for (final exercise in draft.exercises)
            if (exercise.exerciseId != exerciseId) exercise,
          if (!exists)
            WorkoutExerciseDraft(
              exerciseId: exerciseId,
              sets: [const WorkoutSetDraft(id: '0')],
            ),
        ],
      ),
    );
  }

  Future<void> discard() {
    if (_finishing) throw StateError('Workout is being saved.');
    return _save(null);
  }

  Future<void> finish(WorkoutSessionRepository repository) async {
    if (_finishing) throw StateError('Workout is already being saved.');
    final draft = state.value;
    if (draft == null || !draft.isValid) {
      throw StateError('Complete every set with valid kg and reps.');
    }
    _finishing = true;
    try {
      // Keep the completed copy locally as well. A retry uses the same session
      // id and finish time, so interruption cannot create a duplicate workout.
      final completed = draft.isFinished
          ? draft
          : draft.copyWith(finishedAt: DateTime.now().toUtc());
      await _save(completed);
      await repository.save(completed.toSession());
    } finally {
      _finishing = false;
    }
  }
}
