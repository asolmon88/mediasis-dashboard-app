import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/presentation/widgets/orders_screen/order_detail_formatters.dart';

String mapOrderStatusToSpanish(String status) {
  const mapping = <String, String>{
    'pending': 'Pendiente',
    'new': 'Nueva',
    'preparing': 'Preparando',
    'ready_for_pickup': 'Lista para recoger',
    'on_the_way': 'En camino',
    'ready': 'Entregada',
    'accepted': 'Aceptada',
    'delivered': 'Entregada',
    'cancelled': 'Cancelada',
  };

  return mapping[status] ?? status;
}

String mapPaymentStatusToSpanish(String status) {
  switch (status) {
    case 'paid':
      return 'Pagada';
    case 'pending':
      return 'Rechazada';
    default:
      return status;
  }
}

double? calculateVisibleTotal(OrdersTableRow row) {
  final baseTotal = row.total != null && row.total!.isFinite ? row.total : null;
  final deliveryPrice = row.deliveryPrice != null && row.deliveryPrice!.isFinite
      ? row.deliveryPrice!
      : 0.0;

  if (baseTotal == null) return null;
  return baseTotal + (deliveryPrice > 0 ? deliveryPrice : 0);
}

String formatOrdersTableDate(String value, {BusinessMarketSettings? market}) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return '-';

  return market?.formatDate(parsed) ?? '-';
}

String formatVisibleTotal(
  OrdersTableRow row, {
  BusinessMarketSettings? market,
}) {
  return formatCurrencyValue(calculateVisibleTotal(row), market: market);
}
