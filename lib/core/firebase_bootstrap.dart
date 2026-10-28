import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:gymgym_a/firebase_options.dart';

/// Native production options are supplied by `flutterfire configure`.
/// Explicit demo options can only be selected in debug emulator builds.
Future<void> initializeFirebase() async {
  const emulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  const emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  if (emulators && !kDebugMode) {
    throw StateError('Firebase emulators are restricted to debug builds.');
  }
  await Firebase.initializeApp(
    options: emulators
        ? const FirebaseOptions(
            apiKey: 'demo-key',
            appId: '1:000000000000:android:0000000000000000',
            messagingSenderId: '000000000000',
            projectId: 'demo-gymgym',
          )
        : DefaultFirebaseOptions.currentPlatform,
  );
  final firestore = FirebaseFirestore.instance;
  // Set before the first read/write. Android and iOS persist to disk.
  firestore.settings = const Settings(persistenceEnabled: true);
  if (emulators) {
    final host = emulatorHost.isNotEmpty
        ? emulatorHost
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    firestore.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  }
}
