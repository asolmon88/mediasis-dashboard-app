import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/presentation/market_context.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../receipt_actions.dart';
import 'pickup_now_button.dart';
import 'order_action_button.dart';
import 'order_preparation_countdown.dart';
import 'package:mediasis_dashboard_app/utils/duration_extensions.dart';

bool orderCardShowsElapsedTimer(OrderSummary order) =>
    !(order.requiresCourier &&
        order.uberDeliveryStatus?.toLowerCase() == 'dropoff');

bool orderCardIsOnTheWay(OrderSummary order) =>
    order.orderStatus == 'on_the_way' ||
    (order.requiresCourier &&
        order.uberDeliveryStatus?.toLowerCase() == 'dropoff');

class OrderCardWidget extends StatelessWidget {
  const OrderCardWidget({
    super.key,
    required this.order,
    required this.now,
    this.onTap,
    this.onForwardPressed,
    this.onBackwardPressed,
    this.forwardLabel,
  });

  final OrderSummary order;
  final DateTime now;
  final VoidCallback? onTap;
  final VoidCallback? onForwardPressed;
  final VoidCallback? onBackwardPressed;
  final String? forwardLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compactCard = !isCompactWindow(context);
    final elapsedSeconds = _elapsedSeconds();
    final isDelivered =
        order.orderStatus == 'ready' || order.orderStatus == 'delivered';
    final isReadyForPickup = order.orderStatus == 'ready_for_pickup';
    final isOnTheWay = orderCardIsOnTheWay(order);
    final uberStatus = order.uberDeliveryStatus?.toLowerCase();
    final showElapsedTimer = orderCardShowsElapsedTimer(order);
    final showReadyForPickup =
        isReadyForPickup &&
        uberStatus != 'dropoff' &&
        uberStatus != 'delivered';
    final hasForwardAction =
        onForwardPressed != null && (forwardLabel?.isNotEmpty ?? false);
    final hasBackwardAction = onBackwardPressed != null;
    final hasReceipt = _parsedExternalUri(order.receiptUrl) != null;
    final hasTracking = _parsedExternalUri(order.trackingLink) != null;
    final titleText = (order.humanOrderNumber ?? '').isNotEmpty
        ? 'Orden #${order.humanOrderNumber}'
        : 'Orden';

    final urgency = _urgencyLabel(context, elapsedSeconds);
    final preparationCountdown = formatPreparationCountdown(
      order.pickupReadyDt,
      now,
      readyLabel: context.tr('Listo'),
      overdueLabel: context.tr('Atrasado'),
    );
    final pickupReadyAt = order.pickupReadyDt == null
        ? null
        : DateTime.tryParse(order.pickupReadyDt!);
    final preparationIsOverdue = pickupReadyAt?.isBefore(now) ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(1.6.ws(context).clamp(14.0, 18.0)),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.all(1.3.ws(context).clamp(14.0, 16.0)),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(
              1.6.ws(context).clamp(14.0, 18.0),
            ),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 0.5.hs(context).clamp(4.0, 6.0)),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 1.9.hs(context).clamp(15.0, 17.0),
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 0.7.ws(context).clamp(6.0, 8.0)),
                            Expanded(
                              child: Text(
                                '${order.client.firstName} ${order.client.lastName}',
                                style: theme.textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (order.uberDeliveryStatus != null) ...[
                          SizedBox(height: 0.5.hs(context).clamp(4.0, 5.0)),
                          _UberStatusBadge(status: order.uberDeliveryStatus!),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OrderAmountChip(
                        amount:
                            context.market?.formatMoney(order.amount) ?? '-',
                      ),
                      if (!isDelivered && showElapsedTimer) ...[
                        SizedBox(width: 0.8.ws(context).clamp(7.0, 9.0)),
                        Tooltip(
                          message: urgency,
                          child: Semantics(
                            label: urgency,
                            child: Container(
                              height: 1.2.hs(context).clamp(10.0, 12.0),
                              width: 1.2.hs(context).clamp(10.0, 12.0),
                              decoration: BoxDecoration(
                                color: _urgencyColor(elapsedSeconds),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              SizedBox(height: 1.1.hs(context)),
              Wrap(
                spacing: 0.8.ws(context).clamp(8.0, 10.0),
                runSpacing: 0.8.hs(context).clamp(8.0, 10.0),
                children: [
                  if (hasReceipt)
                    OrderActionButton(
                      onPressed: () => _openReceiptLink(context),
                      icon: Icons.receipt_long_rounded,
                      compact: compactCard,
                      label: const LocalizedText('Ver recibo'),
                    ),
                  if (hasTracking)
                    OrderActionButton(
                      onPressed: () => _openTrackingLink(context),
                      icon: Icons.open_in_new_rounded,
                      emphasized: true,
                      compact: compactCard,
                      label: const LocalizedText('Rastreo'),
                    ),
                  PickupNowButton(
                    orderId: order.orderId,
                    requiresCourier: order.requiresCourier,
                    deliveryId: order.uberDeliveryId,
                    trackingLink: order.trackingLink,
                    deliveryStatus: order.uberDeliveryStatus,
                    orderStatus: order.orderStatus,
                    compact: compactCard,
                  ),
                  if (!hasTracking)
                    LocalizedText(
                      'Sin rastreo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 1.4.hs(context)),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrowCard = constraints.maxWidth < 300;
                  final statusContent = Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (showElapsedTimer)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 0.8.ws(context).clamp(8.0, 10.0),
                            vertical: 0.6.hs(context).clamp(5.0, 7.0),
                          ),
                          decoration: BoxDecoration(
                            color: _urgencyColor(
                              elapsedSeconds,
                            ).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 1.8.hs(context).clamp(14.0, 18.0),
                                color: _urgencyColor(elapsedSeconds),
                              ),
                              SizedBox(width: 0.6.ws(context).clamp(6.0, 8.0)),
                              Text(
                                _formatElapsed(elapsedSeconds),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _urgencyColor(elapsedSeconds),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isDelivered || showReadyForPickup || isOnTheWay) ...[
                        SizedBox(width: 0.8.ws(context).clamp(8.0, 10.0)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 0.6.hs(context).clamp(5.0, 7.0),
                          ),
                          child: LocalizedText(
                            isDelivered
                                ? 'Entregada'
                                : isOnTheWay
                                ? 'En camino'
                                : 'Lista para recoger',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else if (order.pickupReadyDt != null) ...[
                        SizedBox(width: 0.8.ws(context).clamp(8.0, 10.0)),
                        _PreparationStatusBadge(
                          label: preparationCountdown,
                          isOverdue: preparationIsOverdue,
                        ),
                      ],
                    ],
                  );

                  final details = LocalizedText(
                    'Ver detalles',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  );

                  return narrowCard
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            statusContent,
                            SizedBox(height: 6),
                            details,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: statusContent),
                            const SizedBox(width: 8),
                            details,
                          ],
                        );
                },
              ),
              if (hasForwardAction || hasBackwardAction) ...[
                SizedBox(height: 1.5.hs(context)),
                Row(
                  children: [
                    if (hasBackwardAction)
                      _BackButton(onPressed: onBackwardPressed!),
                    if (hasBackwardAction && hasForwardAction)
                      SizedBox(width: 0.8.ws(context).clamp(8.0, 10.0)),
                    if (hasForwardAction)
                      Expanded(
                        child: SizedBox(
                          height: 4.6.hs(context).clamp(38.0, 46.0),
                          child: FilledButton(
                            onPressed: onForwardPressed,
                            child: LocalizedText(forwardLabel!),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _elapsedSeconds() {
    final startedAt = DateTime.tryParse(order.statusStartedAt);
    if (startedAt == null) return 0;
    return now.difference(startedAt).inSeconds.clamp(0, 999999);
  }

  Color _urgencyColor(int elapsedSeconds) {
    if (elapsedSeconds >= 900) return const Color(0xFFEF4444);
    if (elapsedSeconds >= 300) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  String _urgencyLabel(BuildContext context, int elapsedSeconds) {
    if (elapsedSeconds >= 900) return context.tr('Pedido retrasado');
    if (elapsedSeconds >= 300) return context.tr('Pedido necesita atención');
    return context.tr('Pedido dentro del tiempo esperado');
  }

  String _formatElapsed(int elapsedSeconds) {
    return Duration(seconds: elapsedSeconds).asClock;
  }

  Future<void> _openTrackingLink(BuildContext context) async {
    await _openExternalLink(
      context,
      rawLink: order.trackingLink,
      errorMessage: 'No se pudo abrir el enlace de rastreo.',
    );
  }

  Future<void> _openReceiptLink(BuildContext context) async {
    await showReceiptActions(
      context: context,
      orderId: order.orderId,
      receiptUrl: order.receiptUrl,
    );
  }

  Future<void> _openExternalLink(
    BuildContext context, {
    required String? rawLink,
    required String errorMessage,
  }) async {
    final uri = _parsedExternalUri(rawLink);
    if (uri == null) {
      _showError(context, errorMessage);
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      _showError(context, errorMessage);
    }
  }

  Uri? _parsedExternalUri(String? rawLink) {
    final normalized = rawLink?.trim();
    final candidate = normalized == null || normalized.isEmpty
        ? null
        : normalized.contains('://')
        ? normalized
        : 'https://$normalized';
    final uri = candidate == null || candidate.isEmpty
        ? null
        : Uri.tryParse(candidate);
    if (uri == null || !uri.isAbsolute) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: LocalizedText(message)));
  }
}

class _PreparationStatusBadge extends StatelessWidget {
  const _PreparationStatusBadge({required this.label, required this.isOverdue});

  final String label;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isOverdue
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Container(
      padding: isOverdue
          ? EdgeInsets.symmetric(vertical: 0.6.hs(context).clamp(5.0, 7.0))
          : EdgeInsets.symmetric(
              horizontal: 0.8.ws(context).clamp(8.0, 10.0),
              vertical: 0.6.hs(context).clamp(5.0, 7.0),
            ),
      decoration: isOverdue
          ? null
          : BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isOverdue) ...[
            Icon(
              Icons.local_pharmacy_outlined,
              size: 1.8.hs(context).clamp(14.0, 18.0),
              color: accent,
            ),
            SizedBox(width: 0.6.ws(context).clamp(6.0, 8.0)),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderAmountChip extends StatelessWidget {
  const _OrderAmountChip({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 1.ws(context).clamp(10.0, 12.0),
        vertical: 0.6.hs(context).clamp(5.0, 7.0),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        amount,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

const _uberStatusConfig = <String, (String label, Color color)>{
  'pending': ('Pendiente', Color(0xFF6B7280)),
  'pickup': ('Recogiendo', Color(0xFF1D4ED8)),
  'pickup_complete': ('Recogido', Color(0xFF1D4ED8)),
  'dropoff': ('En camino', Color(0xFF4338CA)),
  'delivered': ('Entregado', Color(0xFF15803D)),
  'canceled': ('Cancelado', Color(0xFFB91C1C)),
  'returned': ('Devuelto', Color(0xFFC2410C)),
};

class _UberStatusBadge extends StatelessWidget {
  const _UberStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final cfg = _uberStatusConfig[status];
    final label = cfg?.$1 ?? status;
    final color = cfg?.$2 ?? const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        'Uber: ${context.tr(label)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 4.6.hs(context).clamp(38.0, 46.0),
      height: 4.6.hs(context).clamp(38.0, 46.0),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 2.hs(context).clamp(16.0, 20.0),
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
