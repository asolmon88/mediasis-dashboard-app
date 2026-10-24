import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'orders_column.dart';

class OrdersBoardView extends StatelessWidget {
  const OrdersBoardView({super.key, required this.now, required this.orders});

  final DateTime now;
  final List<OrderSummary> orders;

  @override
  Widget build(BuildContext context) {
    final groups = OrderBoardGroups(orders);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: 3.5.ws(context),
        vertical: 2.5.hs(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OrdersHeader(total: orders.length),
          SizedBox(height: 2.5.hs(context)),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = 1.5.ws(context).clamp(12.0, 20.0);
              final columnCount = constraints.maxWidth >= 700 ? 3 : 2;
              final columnWidth =
                  (constraints.maxWidth - gap * (columnCount - 1)) /
                  columnCount;
              final columns = [
                OrdersColumn(
                  sections: [
                    OrdersColumnSection(
                      'Nuevas',
                      Icons.auto_awesome,
                      groups[OrderBoardStage.newOrder],
                    ),
                  ],
                  now: now,
                ),
                OrdersColumn(
                  sections: [
                    if (groups[OrderBoardStage.canceled].isNotEmpty)
                      OrdersColumnSection(
                        'Cancelados',
                        Icons.cancel_outlined,
                        groups[OrderBoardStage.canceled],
                      ),
                    OrdersColumnSection(
                      'Preparando',
                      Icons.soup_kitchen_outlined,
                      groups[OrderBoardStage.preparing],
                    ),
                  ],
                  now: now,
                ),
                OrdersColumn(
                  sections: [
                    OrdersColumnSection(
                      'Listas para recoger',
                      Icons.inventory_2_outlined,
                      groups[OrderBoardStage.readyForPickup],
                    ),
                    OrdersColumnSection(
                      'En camino',
                      Icons.local_shipping_outlined,
                      groups[OrderBoardStage.onWay],
                    ),
                    OrdersColumnSection(
                      'Entregadas',
                      Icons.task_alt_rounded,
                      groups[OrderBoardStage.delivered],
                    ),
                  ],
                  now: now,
                ),
              ];

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  for (final column in columns)
                    SizedBox(width: columnWidth, child: column),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordersState = context.watch<OrdersCubit>().state;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 1.2.ws(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            total > 0
                                ? '${context.tr('Pedidos en tiempo real')} '
                                      '($total ${context.tr('abiertos')})'
                                : context.tr('Pedidos en tiempo real'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 1.ws(context).clamp(8.0, 12.0)),
                        OutlinedButton.icon(
                          onPressed: ordersState.businessLocationId.isEmpty
                              ? null
                              : () => context.read<OrdersCubit>().loadOrders(
                                  ordersState.businessLocationId,
                                ),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const LocalizedText('Refrescar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
