import 'package:flutter_test/flutter_test.dart';
import 'package:mediasis_dashboard_app/presentation/widgets/orders_screen/order_preparation_countdown.dart';
import 'package:mediasis_dashboard_app/utils/duration_extensions.dart';

void main() {
  test('formats durations compactly when hours are zero', () {
    expect(const Duration(minutes: 13, seconds: 20).asClock, '13:20');
    expect(
      const Duration(hours: 1, minutes: 13, seconds: 20).asClock,
      '01:13:20',
    );
  });

  test('formats remaining preparation time from pickup_ready_dt', () {
    final now = DateTime.utc(2026, 9, 23, 12);
    final readyAt = now.add(const Duration(minutes: 13, seconds: 20));

    expect(formatPreparationCountdown(readyAt.toIso8601String(), now), '13:20');
  });

  test('reports ready and overdue states', () {
    final now = DateTime.utc(2026, 9, 23, 12);

    expect(formatPreparationCountdown(now.toIso8601String(), now), 'Ready');
    expect(
      formatPreparationCountdown(
        now.subtract(const Duration(minutes: 4, seconds: 12)).toIso8601String(),
        now,
      ),
      'Overdue 04:12',
    );
  });
}
