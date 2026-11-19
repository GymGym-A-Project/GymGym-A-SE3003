import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/exercise_catalog.dart';
import '../../data/models/exercise.dart';
import '../exercises/exercise_filter.dart';
import '../exercises/exercise_widgets.dart';
import 'routine_draft.dart';

/// Picks catalog exercises for the routine draft.
///
/// Search and chip state are local, so the library tab keeps its own filter.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key, this.selection, this.onToggle});

  /// Selection callbacks let the logger reuse search, filters and attribution.
  final Set<String> Function(WidgetRef)? selection;
  final Future<void> Function(WidgetRef, Exercise)? onToggle;

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  MuscleFilter _muscle = MuscleFilter.all;
  String _query = '';

  Future<void> _toggle(Exercise exercise) async {
    if (widget.onToggle != null) {
      try {
        await widget.onToggle!(ref, exercise);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error is StateError
                    ? error.message.toString()
                    : 'Could not save your selection.',
              ),
            ),
          );
        }
      }
      return;
    }
    final draft = ref.read(routineDraftProvider.notifier);
    if (ref.read(routineDraftProvider).contains(exercise.id)) {
      draft.remove(exercise.id);
    } else if (!draft.add(exercise)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'A routine can have at most $maxRoutineExercises exercises.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(exerciseCatalogProvider);
    final selection =
        widget.selection?.call(ref) ??
        ref
            .watch(routineDraftProvider)
            .items
            .map((item) => item.exercise.id)
            .toSet();
    final selected = selection.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Add exercises ($selected/$maxRoutineExercises)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: catalog.when(
        data: (exercises) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search exercises',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (query) => setState(() => _query = query),
              ),
            ),
            MuscleFilterChips(
              selected: _muscle,
              onSelected: (muscle) => setState(() => _muscle = muscle),
            ),
            Expanded(
              child: _PickerList(
                exercises: filterExercises(
                  exercises,
                  muscle: _muscle,
                  query: _query,
                ),
                onToggle: _toggle,
                selectedIds: selection,
              ),
            ),
            if (exercises.isNotEmpty)
              ExerciseAttribution(exercises.first.attribution),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load: $error')),
      ),
    );
  }
}

class _PickerList extends StatelessWidget {
  const _PickerList({
    required this.exercises,
    required this.onToggle,
    required this.selectedIds,
  });

  final List<Exercise> exercises;
  final ValueChanged<Exercise> onToggle;
  final Set<String> selectedIds;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const Center(child: Text('No exercises match your search.'));
    }
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final selected = selectedIds.contains(exercise.id);
        return ListTile(
          leading: ExerciseThumbnail(exercise.thumbPath),
          title: Text(exercise.name),
          subtitle: Text(exerciseSummary(exercise)),
          trailing: Icon(
            selected ? Icons.check_circle : Icons.add_circle_outline,
          ),
          selected: selected,
          onTap: () => onToggle(exercise),
        );
      },
    );
  }
}
