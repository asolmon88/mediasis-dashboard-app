import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps global methods and only location-assigned specific methods', () {
    const rows = [
      DeliveryMethodTableRow(
        uid: 'all',
        visibility: true,
        instructions: '',
        name: 'Pickup',
      ),
      DeliveryMethodTableRow(
        uid: 'assigned',
        visibility: true,
        instructions: '',
        name: 'Express A',
        scope: 'specific',
      ),
      DeliveryMethodTableRow(
        uid: 'another-location',
        visibility: true,
        instructions: '',
        name: 'Express B',
        scope: 'specific',
      ),
    ];

    final filtered = filterDeliveryMethodsForLocation(rows, {'assigned'});

    expect(filtered.map((row) => row.uid), ['all', 'assigned']);
  });
}
