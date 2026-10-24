extension DurationClockFormat on Duration {
  /// Returns a stable clock-style value for timers and elapsed durations.
  ///
  /// The sign is intentionally omitted. Callers should use the surrounding
  /// state label, such as "Overdue", to describe the direction.
  String get asClock {
    final totalSeconds = inSeconds.abs();
    final hours = totalSeconds ~/ Duration.secondsPerHour;
    final minutes =
        (totalSeconds % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
    final seconds = totalSeconds % Duration.secondsPerMinute;

    final minutePart = minutes.toString().padLeft(2, '0');
    final secondPart = seconds.toString().padLeft(2, '0');
    if (hours == 0) return '$minutePart:$secondPart';

    return '${hours.toString().padLeft(2, '0')}:$minutePart:$secondPart';
  }
}
