import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models/exercise.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/routine_providers.dart';
import '../exercises/exercise_widgets.dart';
import '../../data/auth/auth_providers.dart';
import '../logger/active_workout.dart';

class RoutineDetailScreen extends ConsumerWidget {
  const RoutineDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete routine?'),
        content: const Text('This routine will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final repository = ref.read(routineRepositoryProvider);
      if (repository == null) throw StateError('Not signed in');
      await repository.delete(id);
      if (context.mounted) context.go(AppRoutes.routines);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete the routine. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routine = ref.watch(routineByIdProvider(id));
    final catalog = ref.watch(exerciseCatalogProvider);
    const loading = Center(child: CircularProgressIndicator());
    Widget failure(Object error, StackTrace _) =>
        Center(child: Text('Could not load: $error'));
    return Scaffold(
      appBar: AppBar(
        title: Text(routine.value?.name ?? 'Routine'),
        actions: [
          if (routine.value != null) ...[
            IconButton(
              tooltip: 'Edit routine',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.go(AppRoutes.routineEdit(id)),
            ),
            IconButton(
              tooltip: 'Delete routine',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref),
            ),
          ],
        ],
      ),
      body: routine.when(
        data: (routine) => routine == null
            ? const Center(child: Text('Routine not found'))
            : catalog.when(
                data: (exercises) => _RoutineItems(routine, exercises),
                loading: () => loading,
                error: failure,
              ),
        loading: () => loading,
        error: failure,
      ),
    );
  }
}

class _RoutineItems extends ConsumerStatefulWidget {
  const _RoutineItems(this.routine, this.catalog);

  final Routine routine;
  final List<Exercise> catalog;

  @override
  ConsumerState<_RoutineItems> createState() => _RoutineItemsState();
}

class _RoutineItemsState extends ConsumerState<_RoutineItems> {
  bool _starting = false;
  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final uid = ref.read(authStateProvider).value?.id;
      if (uid == null) throw StateError('Please sign in again.');
      await ref.read(activeWorkoutProvider(uid).future);
      final existing = ref.read(activeWorkoutProvider(uid)).value;
      if (existing != null && !existing.isFinished) {
        if (!mounted) return;
        final resume = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Workout already in progress'),
            content: Text(
              'Resume ${existing.routineName}? Your current entries will be kept.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Resume'),
              ),
            ],
          ),
        );
        if (resume != true) return;
      } else {
        await ref
            .read(activeWorkoutProvider(uid).notifier)
            .start(widget.routine);
      }
      if (mounted) context.go(AppRoutes.logger);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start your workout. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routine = widget.routine;
    final catalog = widget.catalog;
    final byId = {for (final exercise in catalog) exercise.id: exercise};
    final attribution = routine.items
        .map((item) => byId[item.exerciseId]?.attribution)
        .nonNulls
        .firstOrNull;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            key: const ValueKey('start-workout'),
            onPressed: _starting ? null : _start,
            icon: const Icon(Icons.play_arrow),
            label: Text(_starting ? 'Starting…' : 'Start workout'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: routine.items.length,
            itemBuilder: (context, index) {
              final item = routine.items[index];
              final exercise = byId[item.exerciseId];
              final sets = item.targetSets;
              return ListTile(
                leading: ExerciseThumbnail(exercise?.thumbPath),
                title: Text(exercise?.name ?? 'Unknown exercise'),
                subtitle: Text(sets == 1 ? '1 set' : '$sets sets'),
              );
            },
          ),
        ),
        if (attribution != null) ExerciseAttribution(attribution),
      ],
    );
  }
}
