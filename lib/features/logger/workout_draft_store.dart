import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'workout_draft.dart';

abstract interface class WorkoutDraftStore {
  Future<WorkoutDraft?> read(String uid);
  Future<void> write(String uid, WorkoutDraft? draft);
}

/// One device-local draft per user; no account can read another user's draft.
class PreferencesWorkoutDraftStore implements WorkoutDraftStore {
  PreferencesWorkoutDraftStore(this.preferences);
  final SharedPreferencesAsync preferences;
  String _key(String uid) => 'workout-draft-v1:$uid';

  @override
  Future<WorkoutDraft?> read(String uid) async {
    final json = await preferences.getString(_key(uid));
    return json == null
        ? null
        : WorkoutDraft.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<void> write(String uid, WorkoutDraft? draft) async {
    if (draft == null) {
      await preferences.remove(_key(uid));
    } else {
      await preferences.setString(_key(uid), jsonEncode(draft.toJson()));
    }
  }
}

final workoutDraftStoreProvider = Provider<WorkoutDraftStore>(
  (ref) => PreferencesWorkoutDraftStore(SharedPreferencesAsync()),
);
