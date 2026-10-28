import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/text_format.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models/exercise.dart';

/// Original size of the bundled GIFs; never shown larger (license rule).
const _gifSize = 180.0;

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref.watch(exerciseByIdProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(exercise.value?.name ?? 'Exercise')),
      body: exercise.when(
        data: (exercise) => exercise == null
            ? Center(child: Text('Exercise not found (id: $id)'))
            : _ExerciseDetails(exercise),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load: $error')),
      ),
    );
  }
}

class _ExerciseDetails extends StatelessWidget {
  const _ExerciseDetails(this.exercise);

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondary = exercise.secondaryMuscles.map(capitalize).join(', ');
    final stepsEn = exercise.instructionSteps['en'] ?? const [];
    final stepsTr = exercise.instructionSteps['tr'] ?? const [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Image.asset(
            exercise.gifPath,
            width: _gifSize,
            height: _gifSize,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              width: _gifSize,
              height: _gifSize,
              child: Icon(Icons.fitness_center, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          exercise.attribution,
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(exercise.name, style: textTheme.headlineSmall),
        if (exercise.nameTr != null)
          Text(exercise.nameTr!, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        _InfoRow('Primary muscle', capitalize(exercise.primaryMuscle)),
        _InfoRow('Target muscle', capitalize(exercise.targetMuscle)),
        _InfoRow('Secondary muscles', secondary.isEmpty ? '—' : secondary),
        _InfoRow('Equipment', capitalize(exercise.equipment)),
        if (stepsEn.isNotEmpty) _Steps(title: 'Instructions', steps: stepsEn),
        if (stepsTr.isNotEmpty) _Steps(title: 'Talimatlar', steps: stepsTr),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final (index, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('${index + 1}. $step'),
          ),
      ],
    );
  }
}
