import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/exercise_catalog.dart';
import '../../data/models/exercise.dart';
import 'exercise_filter.dart';

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
              _Attribution(text: exercises.first.attribution),
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
    final selected = ref.watch(selectedMuscleProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          for (final muscle in MuscleFilter.values)
            ChoiceChip(
              label: Text(muscle.label),
              selected: muscle == selected,
              onSelected: (_) =>
                  ref.read(selectedMuscleProvider.notifier).select(muscle),
            ),
        ],
      ),
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
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          exercise.thumbPath,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.fitness_center),
          ),
        ),
      ),
      title: Text(exercise.name),
      subtitle: Text(
        '${_capitalize(exercise.primaryMuscle)} · '
        '${_capitalize(exercise.equipment)}',
      ),
      onTap: () {
        // TODO(#16): open detail view
      },
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
