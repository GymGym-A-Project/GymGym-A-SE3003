import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../data/auth/auth_providers.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/workout_session_providers.dart';
import '../exercises/exercise_widgets.dart';
import '../routines/exercise_picker_screen.dart';
import 'active_workout.dart';
import 'workout_draft.dart';

class LoggerScreen extends ConsumerStatefulWidget {
  const LoggerScreen({super.key});
  @override
  ConsumerState<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends ConsumerState<LoggerScreen> {
  bool _busy = false;
  bool _showErrors = false;
  String? _validatedDraftId;

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error is StateError
                    ? error.message.toString()
                    : 'Could not save your workout. Please try again.',
              ),
            ),
          );
      }
    }
  }

  Future<void> _finish(String uid) async {
    setState(() {
      _showErrors = true;
      _validatedDraftId = ref.read(activeWorkoutProvider(uid)).value?.id;
      _busy = true;
    });
    await _run(() async {
      final repository = ref.read(workoutSessionRepositoryProvider);
      if (repository == null) throw StateError('Please sign in again.');
      await ref.read(activeWorkoutProvider(uid).notifier).finish(repository);
      if (mounted) context.go(AppRoutes.history);
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _discard(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text(
          'Your current workout entries will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(() => ref.read(activeWorkoutProvider(uid).notifier).discard());
    }
  }

  void _pick(String uid) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ExercisePickerScreen(
        selection: (ref) =>
            ref
                .watch(activeWorkoutProvider(uid))
                .value
                ?.exercises
                .map((e) => e.exerciseId)
                .toSet() ??
            {},
        onToggle: (ref, exercise) => ref
            .read(activeWorkoutProvider(uid).notifier)
            .toggleExercise(exercise.id),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value?.id;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }
    ref.listen(workoutWriteFailuresProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        final saved = ref.read(activeWorkoutProvider(uid)).value;
        final canRetry =
            saved != null && saved.id == value.sessionId && saved.isFinished;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              canRetry
                  ? 'The server could not save your workout. Your last completed workout is kept on this device; retry from the Workout tab.'
                  : 'The server could not save a workout. Please check your history.',
            ),
          ),
        );
      }
    });
    final active = ref.watch(activeWorkoutProvider(uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: active.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not restore your workout.'),
              TextButton(
                onPressed: () => ref.invalidate(activeWorkoutProvider(uid)),
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => _discard(uid),
                child: const Text('Discard saved workout'),
              ),
            ],
          ),
        ),
        data: (draft) {
          if (draft == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No active workout'),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.routines),
                    child: const Text('Choose a routine'),
                  ),
                ],
              ),
            );
          }
          if (draft.isFinished) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Workout saved on this device'),
                    const Text('Offline changes will sync when you reconnect.'),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.history),
                      child: const Text('View history'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _finish(uid),
                      child: const Text('Retry saving workout'),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.routines),
                      child: const Text('Choose next routine'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ref
              .watch(exerciseCatalogProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(exerciseCatalogProvider),
                    child: const Text('Retry loading exercises'),
                  ),
                ),
                data: (exercises) {
                  final byId = {for (final e in exercises) e.id: e};
                  final controller = ref.read(
                    activeWorkoutProvider(uid).notifier,
                  );
                  return AbsorbPointer(
                    absorbing: _busy,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          draft.routineName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text(
                          'Entries are saved on this device as you type.',
                        ),
                        for (final e in draft.exercises)
                          _ExerciseEditor(
                            key: ValueKey('$uid:${draft.id}:${e.exerciseId}'),
                            exercise: byId[e.exerciseId],
                            draft: e,
                            showErrors:
                                _showErrors && _validatedDraftId == draft.id,
                            canRemove: draft.exercises.length > 1,
                            update: (setId, weight, reps) => _run(
                              () => controller.updateSet(
                                e.exerciseId,
                                setId,
                                weight: weight,
                                reps: reps,
                              ),
                            ),
                            addSet: () =>
                                _run(() => controller.addSet(e.exerciseId)),
                            removeSet: (setId) => _run(
                              () => controller.removeSet(e.exerciseId, setId),
                            ),
                            removeExercise: () => _run(
                              () => controller.toggleExercise(e.exerciseId),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _pick(uid),
                          icon: const Icon(Icons.add),
                          label: Text(
                            'Add exercises (${draft.exercises.length}/15)',
                          ),
                        ),
                        FilledButton(
                          key: const ValueKey('finish-workout'),
                          onPressed: () => _finish(uid),
                          child: Text(_busy ? 'Saving…' : 'Finish workout'),
                        ),
                        TextButton(
                          onPressed: () => _discard(uid),
                          child: const Text('Discard workout'),
                        ),
                      ],
                    ),
                  );
                },
              );
        },
      ),
    );
  }
}

class _ExerciseEditor extends StatelessWidget {
  const _ExerciseEditor({
    super.key,
    required this.exercise,
    required this.draft,
    required this.showErrors,
    required this.canRemove,
    required this.update,
    required this.addSet,
    required this.removeSet,
    required this.removeExercise,
  });
  final Exercise? exercise;
  final WorkoutExerciseDraft draft;
  final bool showErrors;
  final bool canRemove;
  final void Function(String, String?, String?) update;
  final VoidCallback addSet;
  final ValueChanged<String> removeSet;
  final VoidCallback removeExercise;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise?.name ?? 'Unknown exercise (${draft.exerciseId})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Remove exercise',
                onPressed: canRemove ? removeExercise : null,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          for (final (i, set) in draft.sets.indexed)
            Padding(
              key: ValueKey(set.id),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, right: 8),
                    child: Text('${i + 1}'),
                  ),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('weight-${draft.exerciseId}-${set.id}'),
                      initialValue: set.weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'kg',
                        errorMaxLines: 3,
                        errorText: showErrors ? set.weightError : null,
                      ),
                      onChanged: (value) => update(set.id, value, null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('reps-${draft.exerciseId}-${set.id}'),
                      initialValue: set.reps,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Reps',
                        errorMaxLines: 3,
                        errorText: showErrors ? set.repsError : null,
                      ),
                      onChanged: (value) => update(set.id, null, value),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove set',
                    onPressed: draft.sets.length > 1
                        ? () => removeSet(set.id)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: addSet,
            icon: const Icon(Icons.add),
            label: const Text('Add set'),
          ),
          if (exercise?.attribution.isNotEmpty ?? false)
            ExerciseAttribution(exercise!.attribution),
        ],
      ),
    ),
  );
}
