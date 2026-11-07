import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../data/repositories/routine_providers.dart';
import '../exercises/exercise_widgets.dart';
import 'exercise_picker_screen.dart';
import 'routine_draft.dart';

class RoutineCreateScreen extends ConsumerStatefulWidget {
  const RoutineCreateScreen({super.key});

  @override
  ConsumerState<RoutineCreateScreen> createState() =>
      _RoutineCreateScreenState();
}

class _RoutineCreateScreenState extends ConsumerState<RoutineCreateScreen> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repository = ref.read(routineRepositoryProvider);
      if (repository == null) throw StateError('Not signed in');
      final existing = await repository.watch().first;
      final routine = ref
          .read(routineDraftProvider)
          .toRoutine(
            id: newRoutineId(),
            order: existing.length,
            updatedAt: DateTime.now(),
          );
      await repository.save(routine);
      if (mounted) context.go(AppRoutes.routines);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the routine. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openPicker() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExercisePickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(routineDraftProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New routine'),
        actions: [
          TextButton(
            key: const ValueKey('routine-save'),
            onPressed: draft.canSave && !_saving ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const ValueKey('routine-name'),
              decoration: const InputDecoration(
                labelText: 'Routine name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: ref.read(routineDraftProvider.notifier).rename,
            ),
          ),
          const SizedBox(height: 16),
          for (final item in draft.items) _DraftItemTile(item),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: _openPicker,
              icon: const Icon(Icons.add),
              label: Text(
                'Add exercises (${draft.items.length}/$maxRoutineExercises)',
              ),
            ),
          ),
          if (draft.items.isNotEmpty)
            ExerciseAttribution(draft.items.first.exercise.attribution),
        ],
      ),
    );
  }
}

class _DraftItemTile extends ConsumerWidget {
  const _DraftItemTile(this.item);

  final RoutineDraftItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.read(routineDraftProvider.notifier);
    final id = item.exercise.id;
    return ListTile(
      leading: ExerciseThumbnail(item.exercise.thumbPath),
      title: Text(item.exercise.name),
      subtitle: Row(
        children: [
          const Flexible(
            child: Text('Target sets', overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            key: ValueKey('sets-decrease-$id'),
            tooltip: 'Fewer sets',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: item.targetSets > minTargetSets
                ? () => draft.changeTargetSets(id, -1)
                : null,
          ),
          Text('${item.targetSets}', key: ValueKey('sets-value-$id')),
          IconButton(
            key: ValueKey('sets-increase-$id'),
            tooltip: 'More sets',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => draft.changeTargetSets(id, 1),
          ),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Remove exercise',
        icon: const Icon(Icons.close),
        onPressed: () => draft.remove(id),
      ),
    );
  }
}
