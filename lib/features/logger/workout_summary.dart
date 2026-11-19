import 'package:flutter/material.dart';

import '../../core/theme/app_text.dart';
import '../../core/theme/gaps.dart';
import '../../core/theme/gym_colors.dart';
import '../../core/widgets/stat_tile.dart';
import '../../data/models/workout_session.dart';
import '../history/history_format.dart';

/// End-of-workout totals: volume, sets, duration and exercise count.
class WorkoutSummary extends StatelessWidget {
  const WorkoutSummary({super.key, required this.session});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    final setCount = session.exercises.fold(
      0,
      (count, e) => count + e.sets.length,
    );
    final duration = session.finishedAt!.difference(session.startedAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.success,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 36, color: colors.bg),
          ),
        ),
        Gap.vM,
        Text(
          'Workout complete',
          style: AppText.title.copyWith(color: colors.text),
          textAlign: TextAlign.center,
        ),
        Gap.vXl,
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Total volume',
                value: formatKg(session.totalVolume),
                accent: true,
              ),
            ),
            Gap.hS,
            Expanded(
              child: StatTile(label: 'Total sets', value: '$setCount'),
            ),
          ],
        ),
        Gap.vS,
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Duration',
                value: formatDuration(duration),
              ),
            ),
            Gap.hS,
            Expanded(
              child: StatTile(
                label: 'Exercises',
                value: '${session.exercises.length}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
