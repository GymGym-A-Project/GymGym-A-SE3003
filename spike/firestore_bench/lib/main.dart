// Week 3 spike: Firestore offline persistence read benchmark.
//
// Writes 30 days of fake workouts (and one lastPerformance doc), then reads
// them 10 times with Source.cache and reports min/median/max on screen and in
// the log (lines prefixed with "BENCH").
//
// Runs against the local Firestore emulator (project demo-gymgym), so no real
// Firebase project or `flutterfire configure` is needed. To run against a real
// project, replace _options with DefaultFirebaseOptions.currentPlatform and
// remove the useFirestoreEmulator call.
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const _options = FirebaseOptions(
  apiKey: 'demo-key',
  appId: '1:000000000000:android:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-gymgym',
);

// 10.0.2.2 is the host machine as seen from the Android emulator.
const _emulatorHost = '10.0.2.2';
const _uid = 'bench-user';
const _workoutCount = 30;
const _runs = 10;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: _options);
  final db = FirebaseFirestore.instance;
  db.useFirestoreEmulator(_emulatorHost, 8080);
  db.settings = const Settings(persistenceEnabled: true);
  runApp(BenchApp(db: db));
}

class BenchResult {
  BenchResult(this.label, List<int> samplesMs)
    : samples = [...samplesMs]..sort();

  final String label;
  final List<int> samples;

  int get min => samples.first;
  int get max => samples.last;
  double get median {
    final mid = samples.length ~/ 2;
    return samples.length.isOdd
        ? samples[mid].toDouble()
        : (samples[mid - 1] + samples[mid]) / 2;
  }

  @override
  String toString() =>
      'BENCH $label: min=${min}ms median=${median}ms max=${max}ms '
      'samples=$samples';
}

Future<void> seed(FirebaseFirestore db) async {
  final user = db.collection('users').doc(_uid);
  final rnd = Random(42);
  final now = DateTime.now();
  final batch = db.batch();
  for (var day = 0; day < _workoutCount; day++) {
    final finishedAt = now.subtract(Duration(days: day));
    batch.set(user.collection('workouts').doc('w$day'), {
      'routineId': 'push-day',
      'startedAt': finishedAt.subtract(const Duration(hours: 1)),
      'finishedAt': finishedAt,
      'exerciseIds': ['0025', '0030', '0047'],
      'exercises': [
        for (final id in ['0025', '0030', '0047'])
          {
            'exerciseId': id,
            'sets': [
              for (var s = 0; s < 3; s++)
                {'weightKg': 40 + rnd.nextInt(40) + 0.5, 'reps': 6 + s},
            ],
          },
      ],
      'totalVolume': 2000 + rnd.nextInt(1500),
    });
  }
  batch.set(user.collection('lastPerformance').doc('0025'), {
    'sets': [
      {'weightKg': 62.5, 'reps': 8},
      {'weightKg': 62.5, 'reps': 7},
    ],
    'workoutId': 'w0',
    'finishedAt': now,
  });
  await batch.commit();
}

Future<BenchResult> measure(String label, Future<void> Function() read) async {
  final samples = <int>[];
  for (var i = 0; i < _runs; i++) {
    final sw = Stopwatch()..start();
    await read();
    sw.stop();
    samples.add(sw.elapsedMilliseconds);
  }
  final result = BenchResult(label, samples);
  debugPrint(result.toString());
  return result;
}

Future<List<BenchResult>> runBench(FirebaseFirestore db) async {
  await seed(db);
  final user = db.collection('users').doc(_uid);
  const cache = GetOptions(source: Source.cache);

  final history = await measure('30-day workouts (Source.cache)', () async {
    final snap = await user
        .collection('workouts')
        .orderBy('finishedAt', descending: true)
        .get(cache);
    assert(snap.docs.length == _workoutCount);
  });
  final ghost = await measure('lastPerformance doc (Source.cache)', () async {
    await user.collection('lastPerformance').doc('0025').get(cache);
  });
  return [history, ghost];
}

class BenchApp extends StatelessWidget {
  const BenchApp({super.key, required this.db});

  final FirebaseFirestore db;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Firestore offline bench')),
        body: FutureBuilder<List<BenchResult>>(
          future: runBench(db),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('${snap.error}'));
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final r in snap.data!)
                  ListTile(
                    title: Text(r.label),
                    subtitle: Text(
                      'min ${r.min} ms · median ${r.median} ms · '
                      'max ${r.max} ms\n${r.samples}',
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
