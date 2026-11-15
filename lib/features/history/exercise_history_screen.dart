import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/exercise_catalog.dart';
import '../../data/repositories/workout_session_providers.dart';
import 'exercise_progress.dart';
import 'history_format.dart';

/// Date-by-date max weight, best set and volume of one exercise.
class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref.watch(exerciseByIdProvider(id)).value;
    final history = ref.watch(workoutHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(exercise?.name ?? 'Exercise history')),
      body: history.when(
        data: (sessions) {
          final entries = exerciseProgress(sessions, id);
          if (entries.isEmpty) {
            return const Center(child: Text('No sets logged yet'));
          }
          final record = entries
              .map((entry) => entry.maxWeightKg)
              .reduce((a, b) => a > b ? a : b);
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text('Top weight: ${formatKg(record)}'),
                subtitle: Text(
                  entries.length == 1
                      ? '1 session'
                      : '${entries.length} sessions',
                ),
              ),
              const Divider(height: 1),
              for (final entry in entries)
                ListTile(
                  key: ValueKey('entry-${entry.sessionId}'),
                  title: Text(formatDay(entry.date)),
                  subtitle: Text(
                    'Best set ${formatSet(entry.bestSet.weightKg, entry.bestSet.reps)}'
                    ' · ${entry.setCount == 1 ? '1 set' : '${entry.setCount} sets'}'
                    ' · Volume ${formatKg(entry.totalVolume)}',
                  ),
                  trailing: Text(
                    formatKg(entry.maxWeightKg),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load: $error')),
      ),
    );
  }
}
