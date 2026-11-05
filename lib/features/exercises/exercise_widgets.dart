import 'package:flutter/material.dart';

import '../../core/text_format.dart';
import '../../data/models/exercise.dart';
import 'exercise_filter.dart';

/// Rounded catalog thumbnail with a placeholder when the media is missing.
class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail(this.path, {super.key});

  /// Null shows the placeholder, for example when an exercise is not in the
  /// catalog.
  final String? path;

  static const _size = 56.0;

  @override
  Widget build(BuildContext context) {
    const placeholder = SizedBox(
      width: _size,
      height: _size,
      child: Icon(Icons.fitness_center),
    );
    final path = this.path;
    if (path == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        path,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

/// The mandatory media credit, shown wherever exercise media appears.
class ExerciseAttribution extends StatelessWidget {
  const ExerciseAttribution(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// Single-choice muscle chips; the owner keeps the selected value.
class MuscleFilterChips extends StatelessWidget {
  const MuscleFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final MuscleFilter selected;
  final ValueChanged<MuscleFilter> onSelected;

  @override
  Widget build(BuildContext context) {
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
              onSelected: (_) => onSelected(muscle),
            ),
        ],
      ),
    );
  }
}

/// `Chest · Barbell` style line under an exercise name.
String exerciseSummary(Exercise exercise) =>
    '${capitalize(exercise.primaryMuscle)} · '
    '${capitalize(exercise.equipment)}';
