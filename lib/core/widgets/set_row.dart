import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/gaps.dart';
import '../theme/gym_colors.dart';
import 'ghost_number_field.dart';

/// One set of an exercise: `# · kg · reps · ✓`. The row turns green once the
/// set holds valid values.
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.number,
    required this.weight,
    required this.reps,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.completed,
    this.weightKey,
    this.repsKey,
    this.completeKey,
    this.ghostWeight,
    this.ghostReps,
    this.weightError,
    this.repsError,
    this.onComplete,
    this.onRemove,
  });

  /// 1-based set number.
  final int number;
  final String weight;
  final String reps;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onRepsChanged;

  /// True when kg and reps are valid; paints the row green.
  final bool completed;

  final Key? weightKey;
  final Key? repsKey;
  final Key? completeKey;
  final String? ghostWeight;
  final String? ghostReps;
  final String? weightError;
  final String? repsError;

  /// Confirms the ghost values; null hides the ✓ button.
  final VoidCallback? onComplete;

  /// Removes the set; null disables the button (last remaining set).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(Gap.s, Gap.s, 0, Gap.s),
      decoration: BoxDecoration(
        color: completed ? colors.successSurface : Colors.transparent,
        borderRadius: Radii.inputBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 10, right: Gap.s),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: completed ? colors.success : colors.surface2,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppText.label.copyWith(
                letterSpacing: 0,
                fontSize: 12,
                color: completed ? colors.bg : colors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: GhostNumberField(
              key: weightKey,
              value: weight,
              label: 'kg',
              ghost: ghostWeight,
              errorText: weightError,
              decimal: true,
              onChanged: onWeightChanged,
            ),
          ),
          Gap.hS,
          Expanded(
            child: GhostNumberField(
              key: repsKey,
              value: reps,
              label: 'Reps',
              ghost: ghostReps,
              errorText: repsError,
              onChanged: onRepsChanged,
            ),
          ),
          SizedBox(
            width: Gap.touch,
            child: onComplete == null
                ? (completed
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Icon(Icons.check, color: colors.success),
                        )
                      : null)
                : IconButton(
                    key: completeKey,
                    tooltip: 'Complete set',
                    onPressed: onComplete,
                    style: IconButton.styleFrom(
                      backgroundColor: completed
                          ? colors.success
                          : colors.surface2,
                      foregroundColor: completed ? colors.bg : colors.success,
                    ),
                    icon: const Icon(Icons.check),
                  ),
          ),
          IconButton(
            tooltip: 'Remove set',
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
          ),
        ],
      ),
    );
  }
}
