import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models/exercise.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search exercises',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          isDense: true,
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
      return const Center(child: Text('No exercises match your search.'));
    }
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) => _ExerciseTile(exercises[index]),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile(this.exercise);

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ExerciseThumbnail(exercise.thumbPath),
      title: Text(exercise.name),
      subtitle: Text(exerciseSummary(exercise)),
      onTap: () => context.go(AppRoutes.exerciseDetail(exercise.id)),
    );
  }
}
