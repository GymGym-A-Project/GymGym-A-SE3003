import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/set_entry.dart';
import '../../data/models/workout_session.dart';
import '../../data/repositories/workout_session_providers.dart';

/// Last completed performance per exercise before this workout started.
/// This is a read model of workout history, not another writable collection.
Map<String, List<SetEntry>> previousSets(
  Iterable<WorkoutSession> sessions, {
  required DateTime before,
}) {
  final completed =
      sessions
          .where((s) => s.finishedAt != null && !s.finishedAt!.isAfter(before))
          .toList()
        ..sort((a, b) {
          final finish = b.finishedAt!.compareTo(a.finishedAt!);
          if (finish != 0) return finish;
          final start = b.startedAt.compareTo(a.startedAt);
          return start != 0 ? start : a.id.compareTo(b.id);
        });
  final result = <String, List<SetEntry>>{};
  for (final session in completed) {
    for (final exercise in session.exercises) {
      if (exercise.sets.isNotEmpty) {
        result.putIfAbsent(
          exercise.exerciseId,
          () => List.unmodifiable(exercise.sets),
        );
      }
    }
  }
  return Map.unmodifiable(result);
}

class GhostValues {
  const GhostValues(this.sets, this.elapsed);
  final Map<String, List<SetEntry>> sets;

  /// Native device-cache read plus lookup; excludes navigation/animation time.
  final Duration elapsed;
}

final ghostValuesProvider = FutureProvider.autoDispose.family<GhostValues, DateTime>((
  ref,
  before,
) async {
  final repository = ref.watch(workoutSessionRepositoryProvider);
  // Refresh when history syncs or changes. All hints still come from the local
  // cache, so a disconnected device never waits for the server before logging.
  ref.watch(workoutHistoryProvider);
  final stopwatch = Stopwatch()..start();
  final sessions = await repository?.getCached() ?? const <WorkoutSession>[];
  final sets = previousSets(sessions, before: before);
  stopwatch.stop();
  if (!kReleaseMode) {
    debugPrint(
      'Ghost cache read + lookup: ${stopwatch.elapsedMicroseconds} us (${sessions.length} sessions)',
    );
  }
  return GhostValues(sets, stopwatch.elapsed);
});

String ghostWeight(double kg) =>
    kg.toString().replaceFirst(RegExp(r'\.0$'), '');
