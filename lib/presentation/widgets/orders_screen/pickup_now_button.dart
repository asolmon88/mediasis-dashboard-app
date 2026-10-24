import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'order_action_button.dart';

const _ineligibleUberStatuses = <String>{
  'pickup',
  'pickup_complete',
  'dropoff',
  'delivered',
  'canceled',
  'returned',
};

bool canRequestPickupNow({
  required bool requiresCourier,
  required String? deliveryId,
  String? trackingLink,
  required String? deliveryStatus,
  required String? orderStatus,
}) {
  final normalizedOrderStatus = orderStatus?.toLowerCase();
  if (normalizedOrderStatus == 'ready_for_pickup' ||
      normalizedOrderStatus == 'ready' ||
      normalizedOrderStatus == 'delivered') {
    return false;
  }
  final hasDeliveryReference =
      (deliveryId ?? '').isNotEmpty || (trackingLink ?? '').isNotEmpty;
  final hasCourierEvidence = requiresCourier || (trackingLink ?? '').isNotEmpty;
  if (!hasCourierEvidence || !hasDeliveryReference) return false;
  return !_ineligibleUberStatuses.contains(deliveryStatus?.toLowerCase());
}

class PickupNowButton extends StatelessWidget {
  const PickupNowButton({
    super.key,
    required this.orderId,
    required this.requiresCourier,
    required this.deliveryId,
    this.trackingLink,
    required this.deliveryStatus,
    required this.orderStatus,
    this.outlined = true,
    this.compact = false,
  });

  final String orderId;
  final bool requiresCourier;
  final String? deliveryId;
  final String? trackingLink;
  final String? deliveryStatus;
  final String? orderStatus;
  final bool outlined;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!canRequestPickupNow(
      requiresCourier: requiresCourier,
      deliveryId: deliveryId,
      trackingLink: trackingLink,
      deliveryStatus: deliveryStatus,
      orderStatus: orderStatus,
    )) {
      return const SizedBox.shrink();
    }

    final loading = context.select<OrdersCubit, bool>(
      (cubit) => cubit.state.pickupNowOrderIds.contains(orderId),
    );
    final onPressed = loading ? null : () => _confirmAndRequest(context);

    return OrderActionButton(
      onPressed: onPressed,
      icon: Icons.delivery_dining_outlined,
      label: const LocalizedText('Recoger ahora'),
      loading: loading,
      emphasized: !outlined,
      compact: compact,
    );
  }

  Future<void> _confirmAndRequest(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const LocalizedText('¿Solicitar recogida ahora?'),
        content: const LocalizedText(
          'Uber intentara enviar al repartidor lo antes posible y entregar '
          'el pedido cuanto antes. La disponibilidad y el tiempo de llegada '
          'dependen de Uber, y puede que el horario no se pueda modificar otra vez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const LocalizedText('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const LocalizedText('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await context.read<OrdersCubit>().requestPickupNow(orderId);
    if (!context.mounted) return;
    final message =
        result.message ??
        (result.changed == false
            ? 'La entrega ya esta programada para recogerse lo antes posible.'
            : result.success
            ? 'Uber recibio la solicitud de recogida inmediata.'
            : 'No se pudo solicitar la recogida ahora.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: LocalizedText(message)));
  }
}
