import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/gaps.dart';
import '../theme/gym_colors.dart';

/// Label + big value, e.g. volume, sets or duration. The value is one text
/// (including its unit) so it reads as a single number for screen readers.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;

  /// Draws the value in the Kor accent colour.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.m),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppText.label.copyWith(color: colors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Gap.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppText.display.copyWith(
                fontSize: 22,
                color: accent ? colors.kor : colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
