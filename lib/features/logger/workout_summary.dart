import 'package:flutter/material.dart';

import '../../data/models/workout_session.dart';
import '../history/history_format.dart';

class WorkoutSummary extends StatelessWidget {
  const WorkoutSummary({super.key, required this.session});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final setCount = session.exercises.fold(
      0,
      (count, e) => count + e.sets.length,
    );
    final duration = session.finishedAt!.difference(session.startedAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Workout complete',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _Metric('Total volume', formatKg(session.totalVolume)),
        _Metric('Total sets', '$setCount'),
        _Metric('Duration', formatDuration(duration)),
        _Metric('Exercises', '${session.exercises.length}'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}
