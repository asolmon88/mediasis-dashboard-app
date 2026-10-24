import 'package:mediasis_dashboard_app/utils/duration_extensions.dart';

String formatPreparationCountdown(
  String? pickupReadyDt,
  DateTime now, {
  String readyLabel = 'Ready',
  String overdueLabel = 'Overdue',
}) {
  final readyAt = pickupReadyDt == null
      ? null
      : DateTime.tryParse(pickupReadyDt);
  if (readyAt == null) return '—';

  final seconds = readyAt.difference(now).inSeconds;
  if (seconds <= 0) {
    if (seconds == 0) return readyLabel;
    return '$overdueLabel ${Duration(seconds: -seconds).asClock}';
  }

  return Duration(seconds: seconds).asClock;
}
