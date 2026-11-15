import '../../data/models/set_entry.dart';
import '../../data/models/workout_session.dart';

/// How one exercise went in one completed session.
class ExerciseProgressEntry {
  const ExerciseProgressEntry({
    required this.sessionId,
    required this.date,
    required this.maxWeightKg,
    required this.bestSet,
    required this.totalVolume,
    required this.setCount,
  });

  final String sessionId;

  /// When the session started.
  final DateTime date;
  final double maxWeightKg;

  /// The heaviest set; more reps win between sets of the same weight, so a
  /// bodyweight exercise reports its longest set.
  final SetEntry bestSet;
  final double totalVolume;
  final int setCount;
}

/// Date-by-date history of [exerciseId] across [sessions], newest first.
///
/// Unfinished sessions and sessions without a set of this exercise are left
/// out.
List<ExerciseProgressEntry> exerciseProgress(
  Iterable<WorkoutSession> sessions,
  String exerciseId,
) {
  final entries = <ExerciseProgressEntry>[];
  for (final session in sessions) {
    if (session.finishedAt == null) continue;
    final exercise = session.exercises
        .where((e) => e.exerciseId == exerciseId)
        .firstOrNull;
    if (exercise == null || exercise.sets.isEmpty) continue;
    final best = exercise.sets.reduce(
      (best, set) =>
          set.weightKg > best.weightKg ||
              (set.weightKg == best.weightKg && set.reps > best.reps)
          ? set
          : best,
    );
    entries.add(
      ExerciseProgressEntry(
        sessionId: session.id,
        date: session.startedAt,
        maxWeightKg: best.weightKg,
        bestSet: best,
        totalVolume: exercise.totalVolume,
        setCount: exercise.sets.length,
      ),
    );
  }
  entries.sort((a, b) {
    final time = b.date.compareTo(a.date);
    return time == 0 ? a.sessionId.compareTo(b.sessionId) : time;
  });
  return List.unmodifiable(entries);
}

/// Ids of every exercise with at least one logged set in a completed
/// session, most recently performed first.
List<String> performedExerciseIds(Iterable<WorkoutSession> sessions) {
  final finished = sessions.where((s) => s.finishedAt != null).toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  final ids = <String>{};
  for (final session in finished) {
    for (final exercise in session.exercises) {
      if (exercise.sets.isNotEmpty) ids.add(exercise.exerciseId);
    }
  }
  return List.unmodifiable(ids);
}
