import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/text_format.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/gaps.dart';
import '../../core/theme/gym_colors.dart';
import '../../core/widgets/attribution_note.dart';
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
      appBar: AppBar(title: const Text('Exercise')),
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
    final colors = GymColors.of(context);
    final secondary = exercise.secondaryMuscles.map(capitalize).join(', ');
    final stepsEn = exercise.instructionSteps['en'] ?? const [];
    final stepsTr = exercise.instructionSteps['tr'] ?? const [];
    // Short, fixed content: build it all at once (a lazy list would skip the
    // last instruction steps until scrolled).
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Gap.screen, Gap.s, Gap.screen, Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            exercise.name,
            style: AppText.title.copyWith(color: colors.text),
          ),
          if (exercise.nameTr != null)
            Text(
              exercise.nameTr!,
              style: AppText.body.copyWith(color: colors.textMuted),
            ),
          Gap.vM,
          Wrap(
            spacing: Gap.s,
            runSpacing: Gap.s,
            children: [
              _Pill(capitalize(exercise.primaryMuscle), accent: true),
              _Pill(capitalize(exercise.equipment)),
            ],
          ),
          Gap.vL,
          Container(
            padding: const EdgeInsets.all(Gap.l),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: Radii.cardBorder,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: Radii.inputBorder,
                  child: Image.asset(
                    exercise.gifPath,
                    width: _gifSize,
                    height: _gifSize,
                    errorBuilder: (context, error, stackTrace) => SizedBox(
                      width: _gifSize,
                      height: _gifSize,
                      child: Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: colors.ghost,
                      ),
                    ),
                  ),
                ),
                AttributionNote(exercise.attribution, center: true),
              ],
            ),
          ),
          Gap.vL,
          _Section(
            title: 'Muscles',
            children: [
              _InfoRow('Primary muscle', capitalize(exercise.primaryMuscle)),
              _InfoRow('Target muscle', capitalize(exercise.targetMuscle)),
              _InfoRow(
                'Secondary muscles',
                secondary.isEmpty ? '—' : secondary,
              ),
              _InfoRow('Equipment', capitalize(exercise.equipment)),
            ],
          ),
          if (stepsEn.isNotEmpty) _Steps(title: 'Instructions', steps: stepsEn),
          if (stepsTr.isNotEmpty) _Steps(title: 'Talimatlar', steps: stepsTr),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? colors.kor.withValues(alpha: 0.16) : colors.surface2,
        borderRadius: Radii.pillBorder,
      ),
      child: Text(
        text,
        style: AppText.body.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: accent ? colors.kor : colors.text,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: AppText.label.copyWith(color: colors.textMuted),
          ),
          Gap.vS,
          Container(
            padding: const EdgeInsets.all(Gap.m),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: Radii.cardBorder,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = GymColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppText.body.copyWith(color: colors.textMuted),
            ),
            TextSpan(
              text: value,
              style: AppText.body.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
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
    final colors = GymColors.of(context);
    return _Section(
      title: title,
      children: [
        for (final (index, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.xs),
            child: Text(
              '${index + 1}. $step',
              style: AppText.body.copyWith(color: colors.text),
            ),
          ),
      ],
    );
  }
}
