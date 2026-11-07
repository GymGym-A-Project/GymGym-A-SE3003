import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models/exercise.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/routine_providers.dart';
import '../exercises/exercise_widgets.dart';
import 'exercise_picker_screen.dart';
import 'routine_draft.dart';
import 'routine_order.dart';

/// Opens the create screen prefilled with the routine [id].
class RoutineEditScreen extends ConsumerWidget {
  const RoutineEditScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routine = ref.watch(routineByIdProvider(id));
    final catalog = ref.watch(exerciseCatalogProvider);
    Widget message(Widget body) => Scaffold(
      appBar: AppBar(title: const Text('Edit routine')),
      body: Center(child: body),
    );
    final loading = message(const CircularProgressIndicator());
    Widget failure(Object error, StackTrace _) =>
        message(Text('Could not load: $error'));
    return routine.when(
      data: (routine) => routine == null
          ? message(const Text('Routine not found'))
          : catalog.when(
              data: (exercises) =>
                  RoutineCreateScreen(routine: routine, catalog: exercises),
              loading: () => loading,
              error: failure,
            ),
      loading: () => loading,
      error: failure,
    );
  }
}

class RoutineCreateScreen extends ConsumerStatefulWidget {
  const RoutineCreateScreen({super.key, this.routine, this.catalog = const []});

  /// The routine to edit, or null to create a new one.
  final Routine? routine;

  /// Resolves the exercises of [routine].
  final List<Exercise> catalog;

  @override
  ConsumerState<RoutineCreateScreen> createState() =>
      _RoutineCreateScreenState();
}

class _RoutineCreateScreenState extends ConsumerState<RoutineCreateScreen> {
  final _name = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final routine = widget.routine;
    if (routine == null) return;
    _name.text = routine.name;
    // A provider cannot change while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(routineDraftProvider.notifier)
          .load(RoutineDraft.fromRoutine(routine, widget.catalog));
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repository = ref.read(routineRepositoryProvider);
      if (repository == null) throw StateError('Not signed in');
      final draft = ref.read(routineDraftProvider);
      final original = widget.routine;
      final routine = original == null
          ? draft.toRoutine(
              id: newRoutineId(),
              order: nextRoutineOrder(await repository.watch().first),
              updatedAt: DateTime.now(),
            )
          : draft.toRoutine(
              id: original.id,
              order: original.order,
              source: original.source,
              updatedAt: DateTime.now(),
            );
      await repository.save(routine);
      if (mounted) {
        context.go(
          original == null
              ? AppRoutes.routines
              : AppRoutes.routineDetail(original.id),
        );
      }
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
    final notifier = ref.read(routineDraftProvider.notifier);
    final attribution = draft.items
        .map((item) => item.exercise.attribution)
        .where((text) => text.isNotEmpty)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine == null ? 'New routine' : 'Edit routine'),
        actions: [
          TextButton(
            key: const ValueKey('routine-save'),
            onPressed: draft.canSave && !_saving ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        buildDefaultDragHandles: false,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TextField(
            key: const ValueKey('routine-name'),
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Routine name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: notifier.rename,
          ),
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            if (attribution != null) ExerciseAttribution(attribution),
          ],
        ),
        itemCount: draft.items.length,
        itemBuilder: (context, index) {
          final item = draft.items[index];
          return _DraftItemTile(
            item,
            index: index,
            key: ValueKey('draft-item-${item.exercise.id}'),
          );
        },
        onReorderItem: notifier.move,
      ),
    );
  }
}

class _DraftItemTile extends ConsumerWidget {
  const _DraftItemTile(this.item, {super.key, required this.index});

  final RoutineDraftItem item;
  final int index;

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Remove exercise',
            icon: const Icon(Icons.close),
            onPressed: () => draft.remove(id),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle, key: ValueKey('drag-exercise-$id')),
          ),
        ],
      ),
    );
  }
}
