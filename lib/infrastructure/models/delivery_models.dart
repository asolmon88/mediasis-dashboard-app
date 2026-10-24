class DeliveryMethodTableRow {
  const DeliveryMethodTableRow({
    required this.uid,
    required this.visibility,
    required this.instructions,
    required this.name,
    this.scope = 'all',
  });

  final String uid;
  final bool visibility;
  final String instructions;
  final String name;
  final String scope;

  factory DeliveryMethodTableRow.fromMap(Map<String, dynamic> map) {
    return DeliveryMethodTableRow(
      uid: map['uid'] as String? ?? '',
      visibility: map['visibility'] as bool? ?? false,
      instructions: map['instructions'] as String? ?? '',
      name: map['name'] as String? ?? '',
      scope: map['scope'] as String? ?? 'all',
    );
  }
}

List<DeliveryMethodTableRow> filterDeliveryMethodsForLocation(
  Iterable<DeliveryMethodTableRow> rows,
  Set<String> assignedMethodIds,
) {
  return rows
      .where(
        (row) =>
            row.scope.toLowerCase() != 'specific' ||
            assignedMethodIds.contains(row.uid),
      )
      .toList(growable: false);
}

int deliveryIntervalToMinutes(String? interval, {int fallback = 5}) {
  if (interval == null || interval.trim().isEmpty) return fallback;

  final hhmmss = RegExp(
    r'^(-?\d+):([0-5]?\d):([0-5]?\d(?:\.\d+)?)$',
  ).firstMatch(interval);
  if (hhmmss != null) {
    final hours = num.tryParse(hhmmss.group(1) ?? '');
    final minutes = num.tryParse(hhmmss.group(2) ?? '');
    final seconds = num.tryParse(hhmmss.group(3) ?? '');
    if (hours == null || minutes == null || seconds == null) return fallback;

    final total = (hours * 60) + minutes + (seconds / 60);
    return deliveryClampMinutes(total.round());
  }

  final verbose = RegExp(
    r'(?:(-?\d+)\s+day[s]?)?\s*(\d+):([0-5]?\d):([0-5]?\d(?:\.\d+)?)',
  ).firstMatch(interval);
  if (verbose != null) {
    final days = num.tryParse(verbose.group(1) ?? '0');
    final hours = num.tryParse(verbose.group(2) ?? '');
    final minutes = num.tryParse(verbose.group(3) ?? '');
    final seconds = num.tryParse(verbose.group(4) ?? '');
    if (days == null || hours == null || minutes == null || seconds == null) {
      return fallback;
    }

    final total = (days * 24 * 60) + (hours * 60) + minutes + (seconds / 60);
    return deliveryClampMinutes(total.round());
  }

  final plainMinutes = num.tryParse(interval);
  if (plainMinutes != null) {
    return deliveryClampMinutes(plainMinutes.round());
  }

  return fallback;
}

int deliveryClampMinutes(int minutes) {
  return minutes.clamp(1, 180);
}

String formatDeliveryMinutesHuman(int minutes) {
  final safeMinutes = deliveryClampMinutes(minutes);
  final hours = safeMinutes ~/ 60;
  final remainingMinutes = safeMinutes % 60;

  if (hours == 0) return '$remainingMinutes min';
  if (remainingMinutes == 0) return '$hours h';
  return '$hours h $remainingMinutes min';
}
