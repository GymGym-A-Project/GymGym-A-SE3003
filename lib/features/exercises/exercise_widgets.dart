import 'package:flutter/material.dart';

import '../../core/text_format.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/gaps.dart';
import '../../core/theme/gym_colors.dart';
import '../../core/widgets/attribution_note.dart';
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
    final colors = GymColors.of(context);
    final placeholder = SizedBox(
      width: _size,
      height: _size,
      child: Icon(Icons.fitness_center, color: colors.ghost),
    );
    final path = this.path;
    return ClipRRect(
      borderRadius: Radii.inputBorder,
      child: ColoredBox(
        color: colors.surface2,
        child: path == null
            ? placeholder
            : Image.asset(
                path,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}

/// Library row: thumbnail, name and `Muscle · Equipment`. Shared by the
/// library and the exercise picker.
class ExerciseTile extends StatelessWidget {
  const ExerciseTile(
    this.exercise, {
    super.key,
    required this.onTap,
    this.trailing,
  });

  final Exercise exercise;
  final VoidCallback onTap;

  /// Defaults to a chevron.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.screen,
        vertical: Gap.xs,
      ),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardBorder,
          side: BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Gap.s),
            child: Row(
              children: [
                ExerciseThumbnail(exercise.thumbPath),
                Gap.hM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: AppText.headline.copyWith(
                          fontSize: 15,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exerciseSummary(exercise),
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ?? Icon(Icons.chevron_right, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The mandatory media credit, shown wherever exercise media appears.
class ExerciseAttribution extends StatelessWidget {
  const ExerciseAttribution(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => AttributionNote(text, center: true);
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
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.screen,
        vertical: Gap.s,
      ),
      child: Row(
        spacing: Gap.s,
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
