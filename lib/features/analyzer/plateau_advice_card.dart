import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import 'plateau_advice.dart';

/// Used by the analyzer result flow; advisory text is owned by the app, not AI.
class PlateauAdviceCard extends StatelessWidget {
  const PlateauAdviceCard({super.key, required this.advice});
  final PlateauAdvice advice;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            advice.isFallback ? 'Library alternatives' : 'AI explanation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text(plateauDisclaimer),
          const SizedBox(height: 8),
          Text(advice.explanation),
          for (final exercise in advice.alternatives)
            TextButton(
              onPressed: () =>
                  context.push(AppRoutes.exerciseDetail(exercise.id)),
              child: Text(exercise.name),
            ),
        ],
      ),
    ),
  );
}
