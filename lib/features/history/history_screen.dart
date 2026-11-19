import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models/workout_session.dart';
import '../../data/repositories/routine_providers.dart';
import '../../data/repositories/workout_session_providers.dart';
import 'exercise_progress.dart';
import 'history_format.dart';
import '../../core/widgets/sign_out_button.dart';

/// Completed workouts, newest first, and the exercises performed in them.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          actions: const [SignOutButton()],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sessions'),
              Tab(text: 'By exercise'),
            ],
          ),
        ),
        body: history.when(
          data: (sessions) => sessions.isEmpty
              ? const Center(child: Text('No completed workouts yet'))
              : TabBarView(
                  children: [_SessionList(sessions), _ExerciseList(sessions)],
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Could not load: $error')),
        ),
      ),
    );
  }
}

/// Exercise names from the catalog; an id stays readable while it loads.
Map<String, String> _exerciseNames(WidgetRef ref) => {
  for (final exercise in ref.watch(exerciseCatalogProvider).value ?? [])
    exercise.id: exercise.name,
};

class _SessionList extends ConsumerWidget {
  const _SessionList(this.sessions);

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = _exerciseNames(ref);
    final routines = {
      for (final routine in ref.watch(routineListProvider).value ?? [])
        routine.id: routine.name,
    };
    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionTile(
          session,
          routineName: routines[session.routineId],
          exerciseNames: names,
          key: ValueKey('session-${session.id}'),
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile(
    this.session, {
    super.key,
    required this.routineName,
    required this.exerciseNames,
  });

  final WorkoutSession session;

  /// Null once the routine has been deleted.
  final String? routineName;
  final Map<String, String> exerciseNames;

  @override
  Widget build(BuildContext context) {
    final count = session.exercises.length;
    final duration = session.finishedAt!.difference(session.startedAt);
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(formatDay(session.startedAt)),
      subtitle: Text(
        [
          routineName ?? 'Workout',
          count == 1 ? '1 exercise' : '$count exercises',
          formatKg(session.totalVolume),
        ].join(' · '),
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        for (final exercise in session.exercises) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              exerciseNames[exercise.exerciseId] ?? 'Unknown exercise',
              style: theme.textTheme.titleSmall,
            ),
          ),
          for (final (index, set) in exercise.sets.indexed)
            Text('Set ${index + 1}: ${formatSet(set.weightKg, set.reps)}'),
          if (exercise.sets.isEmpty) const Text('No sets logged'),
          Text(
            'Volume: ${formatKg(exercise.totalVolume)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const Divider(height: 24),
        Text(
          'Total volume: ${formatKg(session.totalVolume)}',
          style: theme.textTheme.titleSmall,
        ),
        Text('Duration: ${formatDuration(duration)}'),
      ],
    );
  }
}

class _ExerciseList extends ConsumerWidget {
  const _ExerciseList(this.sessions);

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = _exerciseNames(ref);
    final ids = performedExerciseIds(sessions);
    return ListView.builder(
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final id = ids[index];
        final times = exerciseProgress(sessions, id).length;
        return ListTile(
          title: Text(names[id] ?? 'Unknown exercise'),
          subtitle: Text(times == 1 ? '1 session' : '$times sessions'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(AppRoutes.exerciseHistory(id)),
        );
      },
    );
  }
}
