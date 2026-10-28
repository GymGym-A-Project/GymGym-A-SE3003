import 'dart:async';

import '../models/routine.dart';
import 'routine_repository.dart';

/// In-memory repository; each instance represents an independent user scope.
class FakeRoutineRepository implements RoutineRepository {
  FakeRoutineRepository({Iterable<Routine> routines = const []}) {
    for (final routine in routines) {
      _routines[routine.id] = routine;
    }
  }

  final Map<String, Routine> _routines = {};
  final Set<StreamController<List<Routine>>> _listeners = {};

  List<Routine> _snapshot() {
    final positions = {
      for (final (index, id) in _routines.keys.indexed) id: index,
    };
    final routines = _routines.values.toList()
      ..sort((a, b) {
        final order = a.order.compareTo(b.order);
        return order != 0
            ? order
            : positions[a.id]!.compareTo(positions[b.id]!);
      });
    return List.unmodifiable(routines);
  }

  @override
  Stream<List<Routine>> watch() {
    late final StreamController<List<Routine>> controller;
    controller = StreamController<List<Routine>>(
      onListen: () {
        _listeners.add(controller);
        controller.add(_snapshot());
      },
      onCancel: () {
        _listeners.remove(controller);
      },
    );
    return controller.stream;
  }

  void _publish() {
    final snapshot = _snapshot();
    for (final listener in _listeners) {
      listener.add(snapshot);
    }
  }

  @override
  Future<Routine?> get(String id) async => _routines[id];

  @override
  Future<void> save(Routine routine) async {
    _routines[routine.id] = routine;
    _publish();
  }

  @override
  Future<void> delete(String id) async {
    if (_routines.remove(id) != null) _publish();
  }
}
