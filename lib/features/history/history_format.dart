const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// The local calendar day of [time], e.g. `15 Nov 2026`.
String formatDay(DateTime time) {
  final local = time.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// A weight or volume in kilograms with thousands separators and at most one
/// decimal, e.g. `1,234.5 kg` or `60 kg`.
String formatKg(double kg) {
  final tenths = (kg * 10).round();
  final whole = (tenths ~/ 10).toString();
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+$)'),
    (_) => ',',
  );
  final decimal = tenths % 10;
  return decimal == 0 ? '$grouped kg' : '$grouped.$decimal kg';
}

/// One set as `60 kg × 8`.
String formatSet(double weightKg, int reps) => '${formatKg(weightKg)} × $reps';

/// A session length in whole minutes, e.g. `45 min` or `1 h 05 min`.
String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes < 60) return '$minutes min';
  final rest = (minutes % 60).toString().padLeft(2, '0');
  return '${minutes ~/ 60} h $rest min';
}
