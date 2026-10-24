import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'order_card_widget.dart';

class OrdersMobileTabs extends StatelessWidget {
  const OrdersMobileTabs({super.key, required this.now, required this.orders});

  final DateTime now;
  final List<OrderSummary> orders;

  @override
  Widget build(BuildContext context) {
    final tabsHeight = _ordersTabsHeight(context);
    final tabsBottomPadding = _ordersTabsBottomPadding(context);
    final tabsHeaderExtent = tabsHeight + tabsBottomPadding;
    final groups = OrderBoardGroups(orders);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        4.ws(context),
                        1.4.hs(context),
                        4.ws(context),
                        1.6.hs(context),
                      ),
                      child: _OrdersMobileHeader(total: orders.length),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _OrdersTabsHeaderDelegate(
                      extent: tabsHeaderExtent,
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: EdgeInsets.fromLTRB(
                          4.ws(context),
                          0,
                          4.ws(context),
                          tabsBottomPadding,
                        ),
                        child: _OrdersTabs(
                          height: tabsHeight,
                          newCount: groups[OrderBoardStage.newOrder].length,
                          preparingCount:
                              groups[OrderBoardStage.preparing].length +
                              groups[OrderBoardStage.canceled].length,
                          readyCount:
                              groups[OrderBoardStage.readyForPickup].length +
                              groups[OrderBoardStage.onWay].length +
                              groups[OrderBoardStage.delivered].length,
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _OrdersMobileList(
                    sections: [
                      _MobileSection(
                        'Nuevas',
                        groups[OrderBoardStage.newOrder],
                      ),
                    ],
                    now: now,
                  ),
                  _OrdersMobileList(
                    sections: [
                      if (groups[OrderBoardStage.canceled].isNotEmpty)
                        _MobileSection(
                          'Cancelados',
                          groups[OrderBoardStage.canceled],
                        ),
                      _MobileSection(
                        'Preparando',
                        groups[OrderBoardStage.preparing],
                      ),
                    ],
                    now: now,
                  ),
                  _OrdersMobileList(
                    sections: [
                      _MobileSection(
                        'Listas para recoger',
                        groups[OrderBoardStage.readyForPickup],
                      ),
                      _MobileSection(
                        'En camino',
                        groups[OrderBoardStage.onWay],
                      ),
                      _MobileSection(
                        'Entregadas',
                        groups[OrderBoardStage.delivered],
                      ),
                    ],
                    now: now,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _ordersTabsHeight(BuildContext context) {
  return 5.6.hs(context).clamp(44.0, 52.0);
}

double _ordersTabsBottomPadding(BuildContext context) {
  return 1.4.hs(context).clamp(10.0, 14.0);
}

class _OrdersMobileHeader extends StatelessWidget {
  const _OrdersMobileHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordersState = context.watch<OrdersCubit>().state;

    return Column(
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
            SizedBox(width: 1.ws(context).clamp(8.0, 10.0)),
            OutlinedButton.icon(
              onPressed: ordersState.businessLocationId.isEmpty
                  ? null
                  : () {
                      context.read<OrdersCubit>().loadOrders(
                        ordersState.businessLocationId,
                      );
                    },
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(
                  horizontal: 1.ws(context).clamp(8.0, 10.0),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const LocalizedText('Refrescar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _OrdersTabs extends StatelessWidget {
  const _OrdersTabs({
    required this.height,
    required this.newCount,
    required this.preparingCount,
    required this.readyCount,
  });

  final double height;
  final int newCount;
  final int preparingCount;
  final int readyCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(1.8.ws(context).clamp(16.0, 20.0)),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        padding: EdgeInsets.all(0.4.ws(context).clamp(4.0, 6.0)),
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(
            1.4.ws(context).clamp(12.0, 16.0),
          ),
        ),
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurface,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        tabs: [
          Tab(text: '${context.tr('Nuevas')} ($newCount)'),
          Tab(text: '${context.tr('Prep../Cancelados')} ($preparingCount)'),
          Tab(text: '${context.tr('Recoger/Entrega')} ($readyCount)'),
        ],
      ),
    );
  }
}

class _OrdersMobileList extends StatelessWidget {
  const _OrdersMobileList({required this.sections, required this.now});

  final List<_MobileSection> sections;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (sections.every((section) => section.orders.isEmpty)) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.ws(context)),
          child: LocalizedText(
            'No hay pedidos en esta columna.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        4.ws(context),
        0,
        4.ws(context),
        2.4.hs(context),
      ),
      children: [
        for (final section in sections) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 1.2.hs(context)),
            child: Row(
              children: [
                Expanded(
                  child: LocalizedText(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('${section.orders.length}'),
              ],
            ),
          ),
          for (final order in section.orders)
            Padding(
              padding: EdgeInsets.only(bottom: 1.2.hs(context)),
              child: OrderCardWidget(
                order: order,
                now: now,
                onTap: () =>
                    context.read<OrdersCubit>().selectOrder(order.orderId),
                forwardLabel: orderBoardForwardLabel(order),
                onForwardPressed: orderBoardForwardLabel(order) == null
                    ? null
                    : () => context.read<OrdersCubit>().moveOrderForward(
                        order.orderId,
                      ),
                onBackwardPressed: orderBoardShowsBack(order)
                    ? () => context.read<OrdersCubit>().moveOrderBackward(
                        order.orderId,
                      )
                    : null,
              ),
            ),
        ],
      ],
    );
  }
}

class _MobileSection {
  const _MobileSection(this.title, this.orders);
  final String title;
  final List<OrderSummary> orders;
}

class _OrdersTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _OrdersTabsHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _OrdersTabsHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
