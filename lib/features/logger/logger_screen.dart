import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/gaps.dart';
import '../../core/theme/gym_colors.dart';
import '../../core/widgets/attribution_note.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/set_row.dart';
import '../../core/widgets/stat_tile.dart';
import '../../data/auth/auth_providers.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models/exercise.dart';
import '../../data/models/set_entry.dart';
import '../../data/repositories/workout_session_providers.dart';
import '../exercises/exercise_widgets.dart';
import '../history/history_format.dart';
import '../routines/exercise_picker_screen.dart';
import 'active_workout.dart';
import 'workout_draft.dart';
import 'ghost_values.dart';
import 'workout_summary.dart';

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
        error: (_, _) => EmptyState(
          icon: Icons.restore,
          title: 'Could not restore your workout.',
          action: Column(
            children: [
              FilledButton(
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
            return EmptyState(
              icon: Icons.play_arrow_rounded,
              title: 'No active workout',
              message: 'Start a workout from one of your routines.',
              action: FilledButton(
                onPressed: () => context.go(AppRoutes.routines),
                child: const Text('Choose a routine'),
              ),
            );
          }
          if (draft.isFinished) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      draft.routineName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    WorkoutSummary(session: draft.toSession()),
                    const SizedBox(height: 16),
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
                  final ghosts = ref.watch(
                    ghostValuesProvider(draft.startedAt),
                  );
                  final byId = {for (final e in exercises) e.id: e};
                  final controller = ref.read(
                    activeWorkoutProvider(uid).notifier,
                  );
                  return AbsorbPointer(
                    absorbing: _busy,
                    child: ListView(
                      key: const ValueKey('workout-inputs'),
                      padding: const EdgeInsets.fromLTRB(
                        Gap.screen,
                        Gap.s,
                        Gap.screen,
                        Gap.xl,
                      ),
                      children: [
                        _WorkoutHeader(draft: draft),
                        Gap.vM,
                        const _Hint(
                          'Entries are saved on this device as you type.',
                        ),
                        const _Hint(
                          'Enter actual kg and reps, or confirm the previous values with Complete set.',
                        ),
                        if (ghosts.isLoading && !ghosts.hasValue)
                          const _Hint('Loading previous sets…')
                        else if (ghosts.hasError)
                          Row(
                            children: [
                              const Expanded(
                                child: _Hint(
                                  'Previous values unavailable. You can still log your workout.',
                                ),
                              ),
                              TextButton(
                                onPressed: () => ref.invalidate(
                                  ghostValuesProvider(draft.startedAt),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        else if (ghosts.value?.sets.isEmpty ?? true)
                          const _Hint(
                            'No previous sets available on this device yet.',
                          ),
                        Gap.vS,
                        for (final e in draft.exercises)
                          _ExerciseEditor(
                            key: ValueKey('$uid:${draft.id}:${e.exerciseId}'),
                            exercise: byId[e.exerciseId],
                            draft: e,
                            previous:
                                ghosts.value?.sets[e.exerciseId] ?? const [],
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
                        Gap.vS,
                        OutlinedButton.icon(
                          onPressed: () => _pick(uid),
                          icon: const Icon(Icons.add),
                          label: Text(
                            'Add exercises (${draft.exercises.length}/15)',
                          ),
                        ),
                        Gap.vM,
                        FilledButton(
                          key: const ValueKey('finish-workout'),
                          onPressed: () => _finish(uid),
                          child: Text(_busy ? 'Saving…' : 'Finish workout'),
                        ),
                        Gap.vS,
                        TextButton(
                          onPressed: () => _discard(uid),
                          style: TextButton.styleFrom(
                            foregroundColor: GymColors.of(context).danger,
                          ),
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

/// Routine name, "in progress" badge and live volume / set counters.
class _WorkoutHeader extends StatelessWidget {
  const _WorkoutHeader({required this.draft});
  final WorkoutDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    final sets = [for (final e in draft.exercises) ...e.sets];
    final done = sets.where((s) => s.isValid).toList();
    final volume = done.fold(
      0.0,
      (sum, s) => sum + s.parsedWeight! * s.parsedReps!,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.kor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: Gap.s),
            Text(
              'IN PROGRESS',
              style: AppText.label.copyWith(color: colors.kor),
            ),
          ],
        ),
        const SizedBox(height: Gap.xs),
        Text(
          draft.routineName,
          style: AppText.title.copyWith(color: colors.text),
        ),
        Gap.vM,
        Row(
          children: [
            Expanded(
              child: StatTile(label: 'VOLUME', value: formatKg(volume)),
            ),
            Gap.hS,
            Expanded(
              child: StatTile(
                label: 'SETS',
                value: '${done.length} / ${sets.length}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.xs),
    child: Text(
      text,
      style: AppText.body.copyWith(
        fontSize: 13,
        color: GymColors.of(context).textMuted,
      ),
    ),
  );
}

class _ExerciseEditor extends StatelessWidget {
  const _ExerciseEditor({
    super.key,
    required this.exercise,
    required this.draft,
    required this.previous,
    required this.showErrors,
    required this.canRemove,
    required this.update,
    required this.addSet,
    required this.removeSet,
    required this.removeExercise,
  });
  final Exercise? exercise;
  final WorkoutExerciseDraft draft;
  final List<SetEntry> previous;
  final bool showErrors;
  final bool canRemove;
  final void Function(String, String?, String?) update;
  final VoidCallback addSet;
  final ValueChanged<String> removeSet;
  final VoidCallback removeExercise;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.xs, Gap.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExerciseThumbnail(exercise?.thumbPath),
                Gap.hM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise?.name ??
                            'Unknown exercise (${draft.exerciseId})',
                        style: AppText.headline.copyWith(color: colors.kor),
                      ),
                      if (exercise != null)
                        Text(
                          exerciseSummary(exercise!),
                          style: AppText.body.copyWith(
                            fontSize: 13,
                            color: colors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove exercise',
                  onPressed: canRemove ? removeExercise : null,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Gap.vS,
            for (final (i, set) in draft.sets.indexed)
              Padding(
                key: ValueKey(set.id),
                padding: const EdgeInsets.only(bottom: Gap.xs),
                child: SetRow(
                  number: i + 1,
                  weight: set.weight,
                  reps: set.reps,
                  weightKey: ValueKey('weight-${draft.exerciseId}-${set.id}'),
                  repsKey: ValueKey('reps-${draft.exerciseId}-${set.id}'),
                  completeKey: ValueKey(
                    'complete-${draft.exerciseId}-${set.id}',
                  ),
                  ghostWeight: i < previous.length
                      ? ghostWeight(previous[i].weightKg)
                      : null,
                  ghostReps: i < previous.length ? '${previous[i].reps}' : null,
                  weightError: showErrors ? set.weightError : null,
                  repsError: showErrors ? set.repsError : null,
                  completed: set.isValid,
                  onWeightChanged: (value) => update(set.id, value, null),
                  onRepsChanged: (value) => update(set.id, null, value),
                  onComplete: i < previous.length
                      ? () => update(
                          set.id,
                          set.weight.isEmpty
                              ? ghostWeight(previous[i].weightKg)
                              : null,
                          set.reps.isEmpty ? '${previous[i].reps}' : null,
                        )
                      : null,
                  onRemove: draft.sets.length > 1
                      ? () => removeSet(set.id)
                      : null,
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: addSet,
                icon: const Icon(Icons.add),
                label: const Text('Add set'),
              ),
            ),
            if (exercise?.attribution.isNotEmpty ?? false)
              AttributionNote(exercise!.attribution),
          ],
        ),
      ),
    );
  }
}
