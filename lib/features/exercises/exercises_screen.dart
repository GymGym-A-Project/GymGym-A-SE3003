import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/gaps.dart';
import '../../core/theme/gym_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/exercise_catalog.dart';
import 'exercise_filter.dart';
import 'exercise_widgets.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(exerciseCatalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: catalog.when(
        data: (exercises) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SearchField(),
            const _MuscleChips(),
            const Expanded(child: _ExerciseList()),
            if (exercises.isNotEmpty)
              ExerciseAttribution(exercises.first.attribution),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load: $error')),
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.screen, Gap.s, Gap.screen, 0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search exercises',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: ref.read(searchQueryProvider.notifier).update,
      ),
    );
  }
}

class _MuscleChips extends ConsumerWidget {
  const _MuscleChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MuscleFilterChips(
      selected: ref.watch(selectedMuscleProvider),
      onSelected: ref.read(selectedMuscleProvider.notifier).select,
    );
  }
}

class _ExerciseList extends ConsumerWidget {
  const _ExerciseList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(filteredExercisesProvider).value ?? const [];
    if (exercises.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No exercises match your search.',
        message: 'Try another name or muscle group.',
      );
    }
    final colors = GymColors.of(context);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: Gap.s),
      itemCount: exercises.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.screen,
              Gap.xs,
              Gap.screen,
              Gap.s,
            ),
            child: Text(
              exercises.length == 1
                  ? '1 EXERCISE'
                  : '${exercises.length} EXERCISES',
              style: AppText.label.copyWith(color: colors.textMuted),
            ),
          );
        }
        final exercise = exercises[index - 1];
        return ExerciseTile(
          exercise,
          onTap: () => context.go(AppRoutes.exerciseDetail(exercise.id)),
        );
      },
    );
  }
}
