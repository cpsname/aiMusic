import 'package:intl/intl.dart';

/// Media duration rather than a time of day: minutes never wrap at 60.
String mediaDuration(double seconds, String locale) {
  final safe = seconds.isFinite && seconds >= 0 ? seconds.floor() : 0;
  final minutes = NumberFormat('0', locale).format(safe ~/ 60);
  final remainder = NumberFormat('00', locale).format(safe % 60);
  return '$minutes:$remainder';
}

/// The input is a fraction, as reported by upload and generation progress.
String progressPercent(double progress, String locale) =>
    NumberFormat.percentPattern(
      locale,
    ).format(progress.isFinite ? progress.clamp(0, 1) : 0);
