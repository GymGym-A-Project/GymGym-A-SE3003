import 'dart:convert';

import 'package:gymgym_a/features/logger/workout_draft.dart';
import 'package:gymgym_a/features/logger/workout_draft_store.dart';

/// Serialize as the device store does, so tests cannot pass through aliasing.
class MemoryWorkoutDraftStore implements WorkoutDraftStore {
  final Map<String, String> data = {};
  bool fail = false;

  @override
  Future<WorkoutDraft?> read(String uid) async => data[uid] == null
      ? null
      : WorkoutDraft.fromJson(jsonDecode(data[uid]!) as Map<String, dynamic>);

  @override
  Future<void> write(String uid, WorkoutDraft? draft) async {
    if (fail) throw StateError('Device storage unavailable');
    if (draft == null) {
      data.remove(uid);
    } else {
      data[uid] = jsonEncode(draft.toJson());
    }
  }
}
