import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/presentation/market_context.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/presentation/widgets/orders_list_formatters.dart';
import 'package:flutter/material.dart';
import '../receipt_actions.dart';

typedef OrderRowStatusChanged =
    Future<void> Function(
      String orderId,
      String currentStatus,
      String nextStatus,
    );

class OrdersTableView extends StatelessWidget {
  const OrdersTableView({
    required this.rows,
    required this.offset,
    required this.savingByOrderId,
    required this.onChangeRowStatus,
    this.onRowTap,
    super.key,
  });

  final List<OrdersTableRow> rows;
  final int offset;
  final Map<String, bool> savingByOrderId;
  final OrderRowStatusChanged onChangeRowStatus;
  final ValueChanged<OrdersTableRow>? onRowTap;

  @override
  Widget build(BuildContext context) {
    final isPhoneLayout = !isWideWindow(context);

    return isPhoneLayout
        ? _OrdersCardsList(
            rows: rows,
            offset: offset,
            savingByOrderId: savingByOrderId,
            onChangeRowStatus: onChangeRowStatus,
            onRowTap: onRowTap,
          )
        : _OrdersDesktopTable(
            rows: rows,
            offset: offset,
            savingByOrderId: savingByOrderId,
            onChangeRowStatus: onChangeRowStatus,
            onRowTap: onRowTap,
          );
  }
}

class _OrdersDesktopTable extends StatelessWidget {
  const _OrdersDesktopTable({
    required this.rows,
    required this.offset,
    required this.savingByOrderId,
    required this.onChangeRowStatus,
    this.onRowTap,
  });

  final List<OrdersTableRow> rows;
  final int offset;
  final Map<String, bool> savingByOrderId;
  final OrderRowStatusChanged onChangeRowStatus;
  final ValueChanged<OrdersTableRow>? onRowTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2.6.ws(context).clamp(24.0, 30.0)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.78),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 2.6.ws(context).clamp(24.0, 30.0),
            offset: Offset(0, 1.8.hs(context).clamp(14.0, 18.0)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(1.6.ws(context).clamp(14.0, 16.0)),
        child: Column(
          children: [
            _DesktopHeaderRow(theme: theme),
            SizedBox(height: 1.2.hs(context).clamp(10.0, 12.0)),
            ...List.generate(rows.length, (index) {
              final row = rows[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: 1.hs(context).clamp(8.0, 10.0),
                ),
                child: _DesktopDataRow(
                  row: row,
                  index: offset + index + 1,
                  saving: savingByOrderId[row.orderId] == true,
                  onChangeRowStatus: onChangeRowStatus,
                  onTap: onRowTap == null ? null : () => onRowTap!(row),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DesktopHeaderRow extends StatelessWidget {
  const _DesktopHeaderRow({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 2.ws(context).clamp(18.0, 20.0),
        vertical: 1.4.hs(context).clamp(12.0, 14.0),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.72,
        ),
        borderRadius: BorderRadius.circular(1.8.ws(context).clamp(16.0, 18.0)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: LocalizedText('Orden', style: textStyle)),
          Expanded(flex: 3, child: LocalizedText('Cliente', style: textStyle)),
          Expanded(flex: 2, child: LocalizedText('Total', style: textStyle)),
          Expanded(flex: 2, child: LocalizedText('Recibo', style: textStyle)),
          Expanded(flex: 3, child: LocalizedText('Estado', style: textStyle)),
          Expanded(flex: 2, child: LocalizedText('Pago', style: textStyle)),
          Expanded(flex: 3, child: LocalizedText('Creada', style: textStyle)),
        ],
      ),
    );
  }
}

class _DesktopDataRow extends StatelessWidget {
  const _DesktopDataRow({
    required this.row,
    required this.index,
    required this.saving,
    required this.onChangeRowStatus,
    this.onTap,
  });

  final OrdersTableRow row;
  final int index;
  final bool saving;
  final OrderRowStatusChanged onChangeRowStatus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2.ws(context).clamp(18.0, 20.0)),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: 2.ws(context).clamp(18.0, 20.0),
            vertical: 1.6.hs(context).clamp(14.0, 16.0),
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(
              2.ws(context).clamp(18.0, 20.0),
            ),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 1.ws(context).clamp(8.0, 10.0),
                offset: Offset(0, 0.4.hs(context).clamp(4.0, 6.0)),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  formatOrdersTableIdentifier(
                    row: row,
                    fallbackIndex: index,
                    includeLabel: true,
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    _InitialAvatar(name: row.customerName),
                    SizedBox(width: 1.2.ws(context).clamp(10.0, 12.0)),
                    Expanded(
                      child: Text(
                        row.customerName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(formatVisibleTotal(row, market: context.market)),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _ReceiptButton(
                    orderId: row.orderId,
                    receiptUrl: row.receiptUrl,
                    compact: true,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusEditor(
                    row: row,
                    saving: saving,
                    onChangeRowStatus: onChangeRowStatus,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PaymentBadge(status: row.paymentStatus),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  formatOrdersTableDate(row.createdAt, market: context.market),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersCardsList extends StatelessWidget {
  const _OrdersCardsList({
    required this.rows,
    required this.offset,
    required this.savingByOrderId,
    required this.onChangeRowStatus,
    this.onRowTap,
  });

  final List<OrdersTableRow> rows;
  final int offset;
  final Map<String, bool> savingByOrderId;
  final OrderRowStatusChanged onChangeRowStatus;
  final ValueChanged<OrdersTableRow>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows.length, (index) {
        final row = rows[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 1.2.hs(context).clamp(10.0, 14.0)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRowTap == null ? null : () => onRowTap!(row),
              borderRadius: BorderRadius.circular(
                2.4.ws(context).clamp(20.0, 24.0),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    2.4.ws(context).clamp(20.0, 24.0),
                  ),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.74),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.026),
                      blurRadius: 1.8.ws(context).clamp(16.0, 18.0),
                      offset: Offset(0, 1.hs(context).clamp(8.0, 10.0)),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(1.8.ws(context).clamp(16.0, 18.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            formatOrdersTableIdentifier(
                              row: row,
                              fallbackIndex: offset + index + 1,
                            ),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          SizedBox(width: 1.ws(context).clamp(8.0, 10.0)),
                          _InitialAvatar(name: row.customerName),
                          SizedBox(width: 1.ws(context).clamp(8.0, 10.0)),
                          Expanded(
                            child: Text(
                              row.customerName,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.6.hs(context).clamp(6.0, 8.0)),
                      Text(
                        '${formatVisibleTotal(row, market: context.market)} · ${formatOrdersTableDate(row.createdAt, market: context.market)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 1.2.hs(context).clamp(10.0, 12.0)),
                      Wrap(
                        spacing: 1.ws(context).clamp(8.0, 10.0),
                        runSpacing: 1.hs(context).clamp(8.0, 10.0),
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _ReceiptButton(
                            orderId: row.orderId,
                            receiptUrl: row.receiptUrl,
                            compact: true,
                          ),
                          _StatusEditor(
                            row: row,
                            saving: savingByOrderId[row.orderId] == true,
                            onChangeRowStatus: onChangeRowStatus,
                          ),
                          _PaymentBadge(status: row.paymentStatus),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StatusEditor extends StatelessWidget {
  const _StatusEditor({
    required this.row,
    required this.saving,
    required this.onChangeRowStatus,
  });

  final OrdersTableRow row;
  final bool saving;
  final OrderRowStatusChanged onChangeRowStatus;

  @override
  Widget build(BuildContext context) {
    final operationalStatuses =
        row.deliveryRequireLocation && !row.deliveryRequireCourier
        ? const ['new', 'preparing', 'on_the_way', 'delivered']
        : const ['new', 'preparing', 'ready_for_pickup', 'delivered'];
    final options = [
      ...operationalStatuses,
      if (row.paymentManagedByBusiness) 'cancelled',
    ];

    return PopupMenuButton<String>(
      enabled: !saving,
      onSelected: (nextStatus) =>
          onChangeRowStatus(row.orderId, row.orderStatus, nextStatus),
      itemBuilder: (context) => options
          .map(
            (status) => PopupMenuItem<String>(
              value: status,
              child: Text(
                context.tr(mapOrderStatusToSpanish(status)).toUpperCase(),
              ),
            ),
          )
          .toList(growable: false),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 1.2.ws(context).clamp(10.0, 12.0),
          vertical: 0.9.hs(context).clamp(8.0, 9.0),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            2.2.hs(context).clamp(16.0, 999.0),
          ),
          color: _statusBackground(row.orderStatus),
          border: Border.all(color: _statusBorder(row.orderStatus)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr(mapOrderStatusToSpanish(row.orderStatus)),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: _statusForeground(row.orderStatus),
              ),
            ),
            SizedBox(width: 0.6.ws(context).clamp(6.0, 8.0)),
            Icon(
              saving
                  ? Icons.more_horiz_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 1.8.hs(context).clamp(16.0, 18.0),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'paid';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 1.1.ws(context).clamp(10.0, 11.0),
        vertical: 0.8.hs(context).clamp(7.0, 8.0),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.2.hs(context).clamp(16.0, 999.0)),
        color: (isPaid ? Colors.green : Colors.red).withValues(alpha: 0.09),
        border: Border.all(
          color: (isPaid ? Colors.green : Colors.red).withValues(alpha: 0.18),
        ),
      ),
      child: LocalizedText(
        mapPaymentStatusToSpanish(status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }
}

class _ReceiptButton extends StatelessWidget {
  const _ReceiptButton({
    required this.orderId,
    required this.receiptUrl,
    this.compact = false,
  });

  final String orderId;
  final String? receiptUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (_parseExternalUri(receiptUrl) == null) {
      return const SizedBox.shrink();
    }

    final button = OutlinedButton.icon(
      onPressed: () => _openReceipt(context),
      icon: const Icon(Icons.receipt_long_rounded),
      label: const LocalizedText('Ver recibo'),
    );

    if (compact) return button;

    return SizedBox(width: double.infinity, child: button);
  }

  Future<void> _openReceipt(BuildContext context) async {
    await showReceiptActions(
      context: context,
      orderId: orderId,
      receiptUrl: receiptUrl,
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final theme = Theme.of(context);

    return Container(
      width: 3.4.hs(context).clamp(30.0, 34.0),
      height: 3.4.hs(context).clamp(30.0, 34.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
      ),
      child: Text(
        letter,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statusBackground(String status) {
  switch (status) {
    case 'ready_for_pickup':
      return const Color(0xFFEFF6FF);
    case 'on_the_way':
      return const Color(0xFFEEF4FF);
    case 'ready':
    case 'delivered':
      return Colors.green.withValues(alpha: 0.10);
    case 'cancelled':
      return Colors.red.withValues(alpha: 0.10);
    case 'preparing':
      return const Color(0xFFEEF4FF);
    default:
      return const Color(0xFFFFF5E9);
  }
}

Color _statusBorder(String status) {
  switch (status) {
    case 'ready_for_pickup':
      return const Color(0x332563EB);
    case 'on_the_way':
      return const Color(0x334338CA);
    case 'ready':
    case 'delivered':
      return Colors.green.withValues(alpha: 0.16);
    case 'cancelled':
      return Colors.red.withValues(alpha: 0.16);
    case 'preparing':
      return const Color(0x330264FF);
    default:
      return const Color(0x33FF9F0A);
  }
}

Color _statusForeground(String status) {
  switch (status) {
    case 'ready_for_pickup':
      return const Color(0xFF1D4ED8);
    case 'on_the_way':
      return const Color(0xFF4338CA);
    case 'ready':
    case 'delivered':
      return Colors.green.shade700;
    case 'cancelled':
      return Colors.red.shade700;
    case 'preparing':
      return const Color(0xFF0264FF);
    default:
      return const Color(0xFFD97706);
  }
}

String formatOrdersTableIdentifier({
  required OrdersTableRow row,
  required int fallbackIndex,
  bool includeLabel = false,
}) {
  final humanOrderNumber = (row.humanOrderNumber ?? '').trim();
  if (humanOrderNumber.isNotEmpty) {
    return includeLabel ? 'Orden #$humanOrderNumber' : '#$humanOrderNumber';
  }

  final fallback = '#${fallbackIndex.toString().padLeft(3, '0')}';
  return includeLabel ? 'Orden $fallback' : fallback;
}

Uri? _parseExternalUri(String? rawLink) {
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
