import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/presentation/market_context.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../receipt_actions.dart';
import 'order_detail_formatters.dart';
import 'order_ready_time_control.dart';
import 'order_action_button.dart';
import 'pickup_now_button.dart';

Future<void> showOrderDetailSheet({
  required BuildContext context,
  required OrderRealtimeOrder order,
  required OrderSummary? summary,
  required VoidCallback onClose,
  Future<void> Function()? onCallUber,
}) {
  final isPhoneLayout = isCompactWindow(context);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar detalle del pedido',
    barrierColor: Colors.black.withValues(alpha: isPhoneLayout ? 0.28 : 0.22),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _OrderDetailDialog(
        order: order,
        summary: summary,
        onClose: () {
          Navigator.of(context).pop();
          onClose();
        },
        onCallUber: onCallUber,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(opacity: curved, child: child);
    },
  );
}

class _OrderDetailDialog extends StatelessWidget {
  const _OrderDetailDialog({
    required this.order,
    required this.summary,
    required this.onClose,
    this.onCallUber,
  });

  final OrderRealtimeOrder order;
  final OrderSummary? summary;
  final VoidCallback onClose;
  final Future<void> Function()? onCallUber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaSize = MediaQuery.sizeOf(context);
    final isPhoneLayout = isCompactWindow(context);

    if (isPhoneLayout) {
      return SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: const SizedBox.expand(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1, end: 0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder: (context, offsetFactor, child) {
                  return Transform.translate(
                    offset: Offset(0, offsetFactor * 80),
                    child: child,
                  );
                },
                child: Material(
                  color: theme.scaffoldBackgroundColor,
                  elevation: 24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    width: mediaSize.width,
                    height: mediaSize.height * 0.92,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: _OrderDetailSheetContent(
                      order: order,
                      summary: summary,
                      onClose: onClose,
                      onCallUber: onCallUber,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Tablet / desktop: centered dialog
    final dialogWidth = (mediaSize.width * 0.52).clamp(520.0, 720.0);
    final dialogHeight = (mediaSize.height * 0.88).clamp(560.0, 880.0);
    final verticalMargin = 1.6.hs(context).clamp(12.0, 20.0);

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: const SizedBox.expand(),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: verticalMargin),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.94, end: 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Material(
                  color: theme.scaffoldBackgroundColor,
                  elevation: 24,
                  borderRadius: BorderRadius.circular(20),
                  shadowColor: Colors.black.withValues(alpha: 0.22),
                  child: Container(
                    width: dialogWidth,
                    height: dialogHeight,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _OrderDetailSheetContent(
                        order: order,
                        summary: summary,
                        onClose: onClose,
                        onCallUber: onCallUber,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailSheetContent extends StatelessWidget {
  const _OrderDetailSheetContent({
    required this.order,
    required this.summary,
    required this.onClose,
    this.onCallUber,
  });

  final OrderRealtimeOrder order;
  final OrderSummary? summary;
  final VoidCallback onClose;
  final Future<void> Function()? onCallUber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsPrice = order.productsPrice;
    final deliveryPrice = order.deliveryPrice;
    final hasDeliveryPrice = deliveryPrice != null && deliveryPrice > 0;
    final visibleTotalPrice = productsPrice == null
        ? null
        : productsPrice + (hasDeliveryPrice ? deliveryPrice : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            1.8.ws(context).clamp(18.0, 22.0),
            1.8.hs(context).clamp(16.0, 20.0),
            1.8.ws(context).clamp(18.0, 22.0),
            1.2.hs(context).clamp(10.0, 14.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  (order.humanOrderNumber ?? '').isNotEmpty
                      ? '${context.tr('Detalle del pedido')} #${order.humanOrderNumber}'
                      : context.tr('Detalle del pedido'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 1.8.ws(context).clamp(18.0, 22.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PreparationPanel(order: order),
                if (_hasExternalLink(order.receiptUrl) ||
                    _hasExternalLink(summary?.trackingLink) ||
                    canRequestPickupNow(
                      requiresCourier: order.deliveryMethod.requireCourier,
                      deliveryId:
                          order.uberDelivery?.uberDeliveryId ??
                          order.uberDeliveryId,
                      trackingLink:
                          order.uberDelivery?.trackingUrl ?? order.trackingLink,
                      deliveryStatus: order.uberDelivery?.status,
                      orderStatus: order.orderStatus,
                    )) ...[
                  SizedBox(height: 1.2.hs(context).clamp(10.0, 12.0)),
                  Wrap(
                    spacing: 0.8.ws(context).clamp(8.0, 10.0),
                    runSpacing: 0.8.hs(context).clamp(8.0, 10.0),
                    children: [
                      if (_hasExternalLink(order.receiptUrl))
                        OrderActionButton(
                          onPressed: () => showReceiptActions(
                            context: context,
                            orderId: order.orderId,
                            receiptUrl: order.receiptUrl,
                          ),
                          icon: Icons.receipt_long_rounded,
                          compact: false,
                          label: const LocalizedText('Ver recibo'),
                        ),
                      if (_hasExternalLink(summary?.trackingLink))
                        OrderActionButton(
                          onPressed: () => _openExternalLink(
                            context,
                            rawLink: summary?.trackingLink,
                            errorMessage:
                                'No se pudo abrir el enlace de rastreo.',
                          ),
                          icon: Icons.open_in_new_rounded,
                          emphasized: true,
                          compact: false,
                          label: const LocalizedText('Rastreo'),
                        ),
                      PickupNowButton(
                        orderId: order.orderId,
                        requiresCourier: order.deliveryMethod.requireCourier,
                        deliveryId:
                            order.uberDelivery?.uberDeliveryId ??
                            order.uberDeliveryId,
                        trackingLink:
                            order.uberDelivery?.trackingUrl ??
                            order.trackingLink,
                        deliveryStatus: order.uberDelivery?.status,
                        orderStatus: order.orderStatus,
                        outlined: false,
                        compact: false,
                      ),
                    ],
                  ),
                ],
                _SectionDivider(context: context),
                const _SectionTitle(
                  title: 'Productos',
                  icon: Icons.shopping_bag_outlined,
                ),
                SizedBox(height: 1.hs(context).clamp(8.0, 10.0)),
                Text(
                  '${context.tr('Total productos')}: ${formatCurrencyValue(productsPrice, market: context.market)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (hasDeliveryPrice)
                  Padding(
                    padding: EdgeInsets.only(
                      top: 0.5.hs(context).clamp(4.0, 6.0),
                    ),
                    child: LocalizedText(
                      'Delivery: ${formatCurrencyValue(deliveryPrice, market: context.market)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (hasDeliveryPrice)
                  Padding(
                    padding: EdgeInsets.only(
                      top: 0.5.hs(context).clamp(4.0, 6.0),
                    ),
                    child: LocalizedText(
                      'Total visible: ${formatCurrencyValue(visibleTotalPrice, market: context.market)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(height: 1.4.hs(context)),
                ...order.items.map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 1.6.hs(context)),
                    child: _OrderItemTile(item: item),
                  ),
                ),
                _SectionDivider(context: context),
                if (order.discountBreakdown != null) ...[
                  _DiscountBlock(discount: order.discountBreakdown!),
                  _SectionDivider(context: context),
                ],
                const _SectionTitle(
                  title: 'Método de delivery',
                  icon: Icons.local_shipping_outlined,
                ),
                SizedBox(height: 0.9.hs(context).clamp(8.0, 10.0)),
                LocalizedText(
                  order.deliveryMethod.name.isEmpty
                      ? 'No especificado'
                      : order.deliveryMethod.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                _SectionDivider(context: context),
                const _SectionTitle(
                  title: 'Opciones del pedido',
                  icon: Icons.tune_rounded,
                ),
                SizedBox(height: 0.9.hs(context).clamp(8.0, 10.0)),
                _OrderOptionsList(options: order.orderOptions),
                _SectionDivider(context: context),
                const _SectionTitle(
                  title: 'Cliente',
                  icon: Icons.person_outline_rounded,
                ),
                SizedBox(height: 0.9.hs(context).clamp(8.0, 10.0)),
                Text(
                  '${order.client.firstName} ${order.client.lastName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.4.hs(context).clamp(4.0, 5.0)),
                Text(
                  order.client.phoneNumber,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if ((order.client.email ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: 0.4.hs(context).clamp(4.0, 5.0),
                    ),
                    child: Text(
                      order.client.email!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (order.uberDelivery != null ||
                    order.deliveryMethod.requireCourier) ...[
                  _SectionDivider(context: context),
                  _UberDirectSection(
                    uber: order.uberDelivery,
                    requireCourier: order.deliveryMethod.requireCourier,
                    onCallUber: onCallUber,
                  ),
                ],
                SizedBox(height: 2.4.hs(context)),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            1.8.ws(context).clamp(18.0, 22.0),
            1.2.hs(context).clamp(10.0, 14.0),
            1.8.ws(context).clamp(18.0, 22.0),
            1.8.hs(context).clamp(16.0, 20.0),
          ),
          child: SizedBox(
            height: 4.8.hs(context).clamp(40.0, 46.0),
            child: ElevatedButton(
              onPressed: onClose,
              child: const LocalizedText('Cerrar'),
            ),
          ),
        ),
      ],
    );
  }
}

bool _hasExternalLink(String? rawLink) {
  return _parseExternalUri(rawLink) != null;
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

Future<void> _openExternalLink(
  BuildContext context, {
  required String? rawLink,
  required String errorMessage,
}) async {
  final uri = _parseExternalUri(rawLink);
  if (uri == null) {
    _showExternalLinkError(context, errorMessage);
    return;
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

  if (!opened && context.mounted) {
    _showExternalLinkError(context, errorMessage);
  }
}

void _showExternalLinkError(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: LocalizedText(message)));
}

class _PreparationPanel extends StatelessWidget {
  const _PreparationPanel({required this.order});

  final OrderRealtimeOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(1.4.ws(context).clamp(14.0, 18.0)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(1.8.ws(context).clamp(16.0, 20.0)),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: OrderReadyTimeControl(order: order),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 1.9.hs(context).clamp(16.0, 18.0),
          color: theme.colorScheme.primary,
        ),
        SizedBox(width: 0.8.ws(context).clamp(8.0, 10.0)),
        Expanded(
          child: LocalizedText(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 1.6.hs(context).clamp(14.0, 18.0),
      ),
      child: Divider(height: 1, color: Theme.of(context).colorScheme.outline),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final OrderRealtimeItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productOptions = formatProductOptions(
      item.options,
      market: context.market,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            item.image != null && item.image!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(
                      1.ws(context).clamp(8.0, 10.0),
                    ),
                    child: Image.network(
                      item.image!,
                      width: 4.6.hs(context).clamp(40.0, 46.0),
                      height: 4.6.hs(context).clamp(40.0, 46.0),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const _ItemPlaceholder();
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const _ItemPlaceholder(),
                    ),
                  )
                : const _ItemPlaceholder(),
            SizedBox(width: 1.ws(context).clamp(10.0, 12.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productVariantName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.4.hs(context).clamp(4.0, 5.0)),
                  LocalizedText(
                    '${context.tr('Cantidad')}: ${item.quantity}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (productOptions.isNotEmpty) ...[
          SizedBox(height: 0.9.hs(context).clamp(8.0, 10.0)),
          ...productOptions.map(
            (option) => Padding(
              padding: EdgeInsets.only(
                left: 1.4.ws(context).clamp(14.0, 18.0),
                bottom: 0.9.hs(context).clamp(8.0, 10.0),
              ),
              child: _ProductOptionGroup(option: option),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductOptionGroup extends StatelessWidget {
  const _ProductOptionGroup({required this.option});

  final ProductOptionDisplay option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstValue = option.values.isEmpty ? '' : option.values.first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 0.15.hs(context).clamp(1.0, 2.0)),
          child: Text(
            '•',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 0.8.ws(context).clamp(8.0, 10.0)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (option.displayAsBullets && option.values.isNotEmpty) ...[
                SizedBox(height: 0.4.hs(context).clamp(4.0, 5.0)),
                ...option.values.map(
                  (value) => Padding(
                    padding: EdgeInsets.only(
                      bottom: 0.35.hs(context).clamp(3.0, 4.0),
                    ),
                    child: _NestedBulletedBoldValue(value: value),
                  ),
                ),
              ] else if (firstValue.isNotEmpty) ...[
                SizedBox(height: 0.4.hs(context).clamp(4.0, 5.0)),
                Text(
                  firstValue,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NestedBulletedBoldValue extends StatelessWidget {
  const _NestedBulletedBoldValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 0.15.hs(context).clamp(1.0, 2.0)),
          child: Text(
            '•',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 0.7.ws(context).clamp(6.0, 8.0)),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemPlaceholder extends StatelessWidget {
  const _ItemPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 4.6.hs(context).clamp(40.0, 46.0),
      height: 4.6.hs(context).clamp(40.0, 46.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(1.ws(context).clamp(8.0, 10.0)),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Semantics(
        label: 'Product image unavailable',
        image: true,
        child: Icon(
          Icons.local_pharmacy_outlined,
          size: 2.2.hs(context).clamp(18.0, 22.0),
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DiscountBlock extends StatelessWidget {
  const _DiscountBlock({required this.discount});

  final OrderDiscountBreakdown discount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Descuento aplicado',
          icon: Icons.local_offer_outlined,
        ),
        SizedBox(height: 0.8.hs(context).clamp(8.0, 10.0)),
        Text(
          '${discount.title} (${discount.code})',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.2.hs(context)),
        _DetailAmountRow(
          label: 'Subtotal antes del descuento',
          value: formatCurrencyValue(
            discount.orderTotalBeforeDiscount,
            market: context.market,
          ),
        ),
        SizedBox(height: 0.8.hs(context)),
        _DetailAmountRow(
          label: 'Descuento',
          value:
              '-${formatCurrencyValue(discount.discountAmount, market: context.market)}',
          valueColor: const Color(0xFF059669),
        ),
        SizedBox(height: 0.8.hs(context)),
        _DetailAmountRow(
          label: 'Total final',
          value: formatCurrencyValue(
            discount.orderTotalAfterDiscount,
            market: context.market,
          ),
          emphasized: true,
        ),
      ],
    );
  }
}

class _DetailAmountRow extends StatelessWidget {
  const _DetailAmountRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: emphasized
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OrderOptionsList extends StatelessWidget {
  const _OrderOptionsList({required this.options});

  final Object? options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = formatOrderOptions(options, market: context.market);

    if (rows.isEmpty) {
      return LocalizedText(
        'Sin opciones adicionales.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows
          .map((row) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: 1.1.hs(context).clamp(8.0, 12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (row.type == OrderOptionDisplayType.text &&
                      (row.value ?? '').isNotEmpty)
                    _BulletedOptionValue(label: row.label, value: row.value!),
                  if (row.type == OrderOptionDisplayType.media &&
                      (row.mediaUrl ?? '').isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: 0.8.hs(context).clamp(6.0, 8.0),
                          ),
                          child: _MediaLink(mediaUrl: row.mediaUrl!),
                        ),
                      ],
                    ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _BulletedOptionValue extends StatelessWidget {
  const _BulletedOptionValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 0.15.hs(context).clamp(1.0, 2.0)),
          child: Text(
            '•',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 0.8.ws(context).clamp(8.0, 10.0)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.4.hs(context).clamp(4.0, 5.0)),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaLink extends StatelessWidget {
  const _MediaLink({required this.mediaUrl});

  final String mediaUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _openMedia(context),
      borderRadius: BorderRadius.circular(1.ws(context).clamp(8.0, 10.0)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(1.ws(context).clamp(8.0, 10.0)),
            child: Image.network(
              mediaUrl,
              width: 4.6.hs(context).clamp(40.0, 46.0),
              height: 4.6.hs(context).clamp(40.0, 46.0),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _ItemPlaceholder(),
            ),
          ),
          SizedBox(width: 0.8.ws(context).clamp(8.0, 10.0)),
          LocalizedText(
            'Ver imagen',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMedia(BuildContext context) async {
    final uri = Uri.tryParse(mediaUrl);
    if (uri == null || !uri.isAbsolute) {
      _showError(context);
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: LocalizedText('No se pudo abrir la imagen.')),
    );
  }
}

// ─── Uber Direct Section ─────────────────────────────────────────────────────

String? _formatUberTimestamp(
  String? iso,
  BusinessMarketSettings? market,
  BuildContext context,
) {
  if (iso == null || iso.isEmpty) return null;
  try {
    final dt = DateTime.parse(iso);
    final local = market?.localTime(dt);
    if (local == null) return null;
    final selected = AppLanguage.instance.value;
    final locale = selected == 'system'
        ? Localizations.localeOf(context).toLanguageTag()
        : selected;
    return DateFormat.yMMMd(locale).add_jm().format(local);
  } catch (_) {
    return null;
  }
}

const _uberDetailStatusLabels = <String, String>{
  'pending': 'Pendiente',
  'pickup': 'Recogiendo',
  'pickup_complete': 'Recogido',
  'dropoff': 'En camino',
  'delivered': 'Entregado',
  'canceled': 'Cancelado',
  'returned': 'Devuelto',
};

class _UberDirectSection extends StatefulWidget {
  const _UberDirectSection({
    required this.uber,
    required this.requireCourier,
    this.onCallUber,
  });

  final UberDelivery? uber;
  final bool requireCourier;
  final Future<void> Function()? onCallUber;

  @override
  State<_UberDirectSection> createState() => _UberDirectSectionState();
}

class _UberDirectSectionState extends State<_UberDirectSection> {
  bool _callingUber = false;

  bool get _canCallUber {
    if (!widget.requireCourier) return false;
    final uber = widget.uber;
    if (uber == null) return true;
    final s = uber.status ?? '';
    return s == 'canceled' ||
        s == 'returned' ||
        (uber.integrationError != null);
  }

  Future<void> _handleCallUber() async {
    if (_callingUber || widget.onCallUber == null) return;
    setState(() => _callingUber = true);
    try {
      await widget.onCallUber!();
    } finally {
      if (mounted) setState(() => _callingUber = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uber = widget.uber;
    final statusLabel = uber?.status != null
        ? (_uberDetailStatusLabels[uber!.status] ?? uber.status)
        : null;
    final deliveryId = uber?.uberDeliveryId ?? '';
    final isReturn =
        uber?.deliveryRole == 'return' || deliveryId.startsWith('ret_');
    final uberIdDisplay = uber != null
        ? (uber.uberIdLast5 ??
              uber.uberUuid?.substring(
                (uber.uberUuid!.length - 5).clamp(0, uber.uberUuid!.length),
              ) ??
              '')
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 1.8.hs(context).clamp(15.0, 18.0),
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 0.7.ws(context).clamp(6.0, 8.0)),
            LocalizedText(
              'Uber',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (statusLabel != null) ...[
              SizedBox(width: 0.8.ws(context).clamp(6.0, 8.0)),
              _UberBadge(label: statusLabel, status: uber!.status ?? ''),
            ],
            if (isReturn) ...[
              SizedBox(width: 0.6.ws(context).clamp(4.0, 6.0)),
              _UberBadge(label: 'Devolución', status: 'returned'),
            ],
            if (uber?.courierImminent == true) ...[
              SizedBox(width: 0.6.ws(context).clamp(4.0, 6.0)),
              _CourierImminentPill(),
            ],
          ],
        ),

        // Integration error banner
        if (uber?.integrationError != null) ...[
          SizedBox(height: 1.hs(context).clamp(8.0, 10.0)),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  'Error de integración con Uber',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  uber!.integrationError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFDC2626),
                  ),
                ),
                if (uber.integrationErrorAt != null) ...[
                  SizedBox(height: 2),
                  Text(
                    _formatUberTimestamp(
                          uber.integrationErrorAt,
                          context.market,
                          context,
                        ) ??
                        '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFF87171),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Keep the operational delivery window visible before technical details.
        if (uber != null) ...[
          SizedBox(height: 1.hs(context).clamp(8.0, 10.0)),
          _DeliveryTimelineSection(uber: uber),
        ],

        // Uber ID
        if (uberIdDisplay.isNotEmpty) ...[
          SizedBox(height: 0.8.hs(context).clamp(6.0, 8.0)),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Uber ID: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: uberIdDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Courier card
        if (uber != null &&
            uberStatusShowsCourier(uber.status) &&
            (uber.courierName != null ||
                uber.courierVehicleModel != null ||
                uber.courierVehicleColor != null)) ...[
          SizedBox(height: 1.hs(context).clamp(8.0, 10.0)),
          _CourierCard(uber: uber),
        ],

        // Addresses
        if (uber != null &&
            (uber.pickupAddress != null || uber.dropoffAddress != null)) ...[
          SizedBox(height: 1.hs(context).clamp(8.0, 10.0)),
          _AddressesSection(uber: uber),
        ],

        // Proof
        if (uber != null &&
            (uber.proofPictureUrl != null ||
                uber.signatureImageUrl != null ||
                uber.cancellationReason != null ||
                uber.undeliverableReason != null)) ...[
          SizedBox(height: 1.2.hs(context).clamp(10.0, 12.0)),
          _UberProofSection(uber: uber),
        ],

        // Llamar Uber / Re-solicitar Uber button
        if (_canCallUber && widget.onCallUber != null) ...[
          SizedBox(height: 1.2.hs(context).clamp(10.0, 12.0)),
          _CallUberButton(
            hasExisting: uber != null,
            loading: _callingUber,
            onPressed: _handleCallUber,
          ),
        ],
      ],
    );
  }
}

class _UberBadge extends StatelessWidget {
  const _UberBadge({required this.label, required this.status});

  final String label;
  final String status;

  static const _colors = <String, Color>{
    'pending': Color(0xFF6B7280),
    'pickup': Color(0xFF1D4ED8),
    'pickup_complete': Color(0xFF1D4ED8),
    'dropoff': Color(0xFF4338CA),
    'delivered': Color(0xFF15803D),
    'canceled': Color(0xFFB91C1C),
    'returned': Color(0xFFC2410C),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: LocalizedText(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _CourierImminentPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFF97316),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const LocalizedText(
            'Courier en camino',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC2410C),
            ),
          ),
        ],
      ),
    );
  }
}

bool uberStatusShowsCourier(String? status) => const {
  'pickup',
  'pickup_complete',
  'dropoff',
  'delivered',
}.contains(status?.toLowerCase());

class _CourierCard extends StatelessWidget {
  const _CourierCard({required this.uber});

  final UberDelivery uber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = uber.courierName?.isNotEmpty == true
        ? uber.courierName![0].toUpperCase()
        : '?';
    final vehicleText = [
      uber.courierVehicleColor,
      uber.courierVehicleMake,
      uber.courierVehicleModel,
    ].whereType<String>().join(' ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              uber.courierImgHref != null && uber.courierImgHref!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        uber.courierImgHref!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _CourierAvatar(initial: initial),
                      ),
                    )
                  : _CourierAvatar(initial: initial),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (uber.courierName != null)
                      Text(
                        uber.courierName!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (uber.courierPhoneNumber != null)
                      GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse('tel:${uber.courierPhoneNumber}'),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              uber.courierPhoneNumber!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (vehicleText.isNotEmpty ||
              uber.courierVehicleLicensePlate != null) ...[
            Divider(height: 16, color: theme.colorScheme.outline),
            if (vehicleText.isNotEmpty)
              Text(
                vehicleText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (uber.courierVehicleType != null)
              Text(
                uber.courierVehicleType!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (uber.courierVehicleLicensePlate != null)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Placa: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextSpan(
                      text: uber.courierVehicleLicensePlate!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CourierAvatar extends StatelessWidget {
  const _CourierAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DeliveryTimelineSection extends StatelessWidget {
  const _DeliveryTimelineSection({required this.uber});

  final UberDelivery uber;

  @override
  Widget build(BuildContext context) {
    final pickupCompleted = _formatUberTimestamp(
      uber.pickupCompletedAt,
      context.market,
      context,
    );
    final delivered = _formatUberTimestamp(
      uber.deliveredAt,
      context.market,
      context,
    );
    final pickupItems = pickupCompleted != null
        ? [('Recogido', pickupCompleted)]
        : [
            (
              'Uber llega aproximadamente',
              _formatUberTimestamp(uber.pickupEta, context.market, context),
            ),
            (
              'Puede recoger desde',
              _formatUberTimestamp(uber.pickupReady, context.market, context),
            ),
            (
              'A más tardar',
              _formatUberTimestamp(
                uber.pickupDeadline,
                context.market,
                context,
              ),
            ),
          ];
    final deliveryItems = delivered != null
        ? [('Entregado', delivered)]
        : [
            (
              'Llegada estimada',
              _formatUberTimestamp(uber.dropoffEta, context.market, context),
            ),
            (
              'A más tardar',
              _formatUberTimestamp(
                uber.dropoffDeadline,
                context.market,
                context,
              ),
            ),
          ];

    final hasPickup = pickupItems.any((item) => item.$2 != null);
    final hasDelivery = deliveryItems.any((item) => item.$2 != null);
    if (!hasPickup && !hasDelivery) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackCards = constraints.maxWidth < 480;
        final cards = [
          if (hasPickup)
            _DeliveryTimelineCard(
              icon: Icons.storefront_outlined,
              title: 'Recogida',
              items: pickupItems,
              accent: Theme.of(context).colorScheme.primary,
            ),
          if (hasDelivery)
            _DeliveryTimelineCard(
              icon: Icons.home_outlined,
              title: 'Entrega',
              items: deliveryItems,
              accent: const Color(0xFF15803D),
            ),
        ];

        if (stackCards || cards.length == 1) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                cards[index],
                if (index != cards.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index != cards.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _DeliveryTimelineCard extends StatelessWidget {
  const _DeliveryTimelineCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final List<(String, String?)> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleItems = items.where((item) => item.$2 != null).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 7),
              LocalizedText(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          for (var index = 0; index < visibleItems.length; index++) ...[
            LocalizedText(
              visibleItems[index].$1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              visibleItems[index].$2!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (index != visibleItems.length - 1) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _AddressesSection extends StatelessWidget {
  const _AddressesSection({required this.uber});

  final UberDelivery uber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          'Direcciones',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        if (uber.pickupAddress != null)
          _AddressRow(
            label: 'Recogida',
            address: uber.pickupAddress!,
            iconColor: theme.colorScheme.onSurfaceVariant,
          ),
        if (uber.dropoffAddress != null)
          _AddressRow(
            label: 'Entrega',
            address: uber.dropoffAddress!,
            iconColor: theme.colorScheme.primary,
          ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.label,
    required this.address,
    required this.iconColor,
  });

  final String label;
  final String address;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${context.tr(label)}: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(text: address, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UberProofSection extends StatelessWidget {
  const _UberProofSection({required this.uber});

  final UberDelivery uber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (uber.proofPictureUrl != null) ...[
          LocalizedText(
            'Comprobante',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(uber.proofPictureUrl!),
              mode: LaunchMode.externalApplication,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                uber.proofPictureUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
        if (uber.signatureImageUrl != null) ...[
          const SizedBox(height: 10),
          LocalizedText(
            'Firma',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(uber.signatureImageUrl!),
              mode: LaunchMode.externalApplication,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                uber.signatureImageUrl!,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          if (uber.signatureSignerName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: LocalizedText(
                'Firmó: ${uber.signatureSignerName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (uber.signatureSignerRelationship != null)
            LocalizedText(
              'Relación: ${uber.signatureSignerRelationship}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
        if (uber.cancellationReason != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LocalizedText(
                  'Motivo de cancelación',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB91C1C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  uber.cancellationReason!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (uber.undeliverableReason != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LocalizedText(
                  'No entregado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC2410C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  uber.undeliverableReason!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEA580C),
                  ),
                ),
                if (uber.undeliverableAction != null)
                  Text(
                    '${context.tr('Acción')}: ${uber.undeliverableAction}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEA580C),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CallUberButton extends StatelessWidget {
  const _CallUberButton({
    required this.hasExisting,
    required this.loading,
    required this.onPressed,
  });

  final bool hasExisting;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = hasExisting ? 'Re-solicitar Uber' : 'Llamar Uber';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LocalizedText(
              hasExisting
                  ? 'El delivery anterior falló o fue cancelado.'
                  : 'Sin delivery asignado.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: loading ? null : onPressed,
              child: LocalizedText(
                loading ? 'Solicitando...' : label,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
