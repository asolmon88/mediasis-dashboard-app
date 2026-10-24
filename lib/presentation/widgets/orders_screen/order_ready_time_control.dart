import 'dart:async';

import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:flutter/material.dart';

import 'order_preparation_countdown.dart';

class OrderReadyTimeControl extends StatefulWidget {
  const OrderReadyTimeControl({super.key, required this.order});

  final OrderRealtimeOrder? order;

  @override
  State<OrderReadyTimeControl> createState() => _OrderReadyTimeControlState();
}

class _OrderReadyTimeControlState extends State<OrderReadyTimeControl> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    if (order == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final pickupReady = order.uberDelivery?.pickupReady ?? order.pickupReadyDt;
    final readyAt = pickupReady == null ? null : DateTime.tryParse(pickupReady);
    final remainingSeconds = readyAt?.difference(DateTime.now()).inSeconds;
    final isOverdue = remainingSeconds != null && remainingSeconds < 0;
    final accent = isOverdue
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final countdown = formatPreparationCountdown(
      pickupReady,
      DateTime.now(),
      readyLabel: context.tr('Listo'),
      overdueLabel: context.tr('Atrasado'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          'Lista en',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 0.8.hs(context)),
        Container(
          width: double.infinity,
          padding: isOverdue
              ? EdgeInsets.symmetric(vertical: 0.6.hs(context).clamp(6.0, 8.0))
              : EdgeInsets.symmetric(
                  horizontal: 1.2.ws(context).clamp(12.0, 16.0),
                  vertical: 1.hs(context).clamp(10.0, 12.0),
                ),
          decoration: isOverdue
              ? null
              : BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    1.4.ws(context).clamp(12.0, 16.0),
                  ),
                ),
          child: Row(
            children: [
              if (!isOverdue) ...[
                Icon(Icons.timer_outlined, color: accent),
                SizedBox(width: 1.ws(context).clamp(10.0, 12.0)),
              ],
              Expanded(
                child: Text(
                  countdown,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 0.6.hs(context)),
        LocalizedText(
          order.deliveryMethod.requireCourier
              ? 'Horario de preparación informado por Uber.'
              : 'Tiempo estimado para tener el pedido listo.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
