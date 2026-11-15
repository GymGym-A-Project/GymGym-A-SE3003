import 'package:flutter_test/flutter_test.dart';
import 'package:gymgym_a/features/history/history_format.dart';

void main() {
  test('formatDay shows the local calendar day', () {
    expect(formatDay(DateTime(2026, 11, 15, 18)), '15 Nov 2026');
    expect(formatDay(DateTime(2026, 1, 3)), '3 Jan 2026');
  });

  test('formatKg groups thousands and keeps at most one decimal', () {
    expect(formatKg(0), '0 kg');
    expect(formatKg(60), '60 kg');
    expect(formatKg(62.5), '62.5 kg');
    expect(formatKg(1234.5), '1,234.5 kg');
    expect(formatKg(1000000), '1,000,000 kg');
    expect(formatKg(47.25), '47.3 kg');
    expect(formatKg(99.96), '100 kg');
  });

  test('formatSet shows weight and reps', () {
    expect(formatSet(60, 8), '60 kg × 8');
    expect(formatSet(0, 12), '0 kg × 12');
  });

  test('formatDuration shows minutes, and hours past the first hour', () {
    expect(formatDuration(const Duration(seconds: 59)), '0 min');
    expect(formatDuration(const Duration(minutes: 45)), '45 min');
    expect(formatDuration(const Duration(minutes: 65)), '1 h 05 min');
    expect(formatDuration(const Duration(hours: 2)), '2 h 00 min');
  });
}
