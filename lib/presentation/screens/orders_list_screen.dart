import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:mediasis_dashboard_app/presentation/widgets/orders_list/orders_table_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = context.watch<LocationCubit>().state;
    final selectedLocation = locationState.selectedLocation;

    return BlocListener<OrdersTableCubit, OrdersTableState>(
      listenWhen: (previous, current) =>
          previous.transientMessage != current.transientMessage,
      listener: (context, state) {
        if (state.transientMessage.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: LocalizedText(state.transientMessage)),
        );
        context.read<OrdersTableCubit>().clearTransientMessage();
      },
      child: BlocBuilder<OrdersTableCubit, OrdersTableState>(
        builder: (context, state) {
          if (_searchController.text != state.searchQuery) {
            _searchController.value = TextEditingValue(
              text: state.searchQuery,
              selection: TextSelection.collapsed(
                offset: state.searchQuery.length,
              ),
            );
          }

          if (selectedLocation != null &&
              state.businessLocationId != selectedLocation.businessLocationId &&
              state.status != OrdersTableStatus.loading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<OrdersTableCubit>().loadForLocation(
                selectedLocation.businessLocationId,
              );
            });
          }

          final horizontalPadding = 4.ws(context).clamp(16.0, 40.0);

          return RefreshIndicator(
            onRefresh: () => context.read<OrdersTableCubit>().refresh(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                3.2.hs(context).clamp(20.0, 28.0),
              ),
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      2.6.ws(context).clamp(24.0, 30.0),
                    ),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.78),
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
                    padding: EdgeInsets.all(2.2.ws(context).clamp(18.0, 26.0)),
                    child: _OrdersListHeader(
                      state: state,
                      searchController: _searchController,
                      onRefresh: () => _refreshOrdersList(),
                    ),
                  ),
                ),
                if (state.status == OrdersTableStatus.loading &&
                    state.rows.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: 1.2.hs(context).clamp(10.0, 14.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(
                        Radius.circular(2.hs(context).clamp(12.0, 999.0)),
                      ),
                      child: LinearProgressIndicator(
                        minHeight: 0.5.hs(context).clamp(4.0, 6.0),
                      ),
                    ),
                  ),
                if (state.status == OrdersTableStatus.loading &&
                    state.rows.isEmpty) ...[
                  SizedBox(height: 2.4.hs(context).clamp(20.0, 24.0)),
                  const Center(child: CircularProgressIndicator()),
                ] else if (state.status == OrdersTableStatus.failure) ...[
                  SizedBox(height: 2.4.hs(context).clamp(20.0, 24.0)),
                  _OrdersTableMessageCard(
                    icon: Icons.error_outline_rounded,
                    title: 'No se pudieron cargar las órdenes',
                    subtitle: state.errorMessage,
                    actionLabel: 'Reintentar',
                    onAction: () => context.read<OrdersTableCubit>().refresh(),
                  ),
                ] else if (state.visibleRows.isEmpty) ...[
                  SizedBox(height: 2.4.hs(context).clamp(20.0, 24.0)),
                  _OrdersTableMessageCard(
                    icon: Icons.receipt_long_outlined,
                    title: state.searchQuery.trim().isEmpty
                        ? 'No hay pedidos pagados para mostrar'
                        : 'No hay resultados',
                    subtitle: state.searchQuery.trim().isEmpty
                        ? 'Cuando entren pedidos pagados para esta ubicación, aparecerán aquí.'
                        : 'Prueba con otra búsqueda.',
                    actionLabel: 'Actualizar',
                    onAction: () => context.read<OrdersTableCubit>().refresh(),
                  ),
                ] else ...[
                  SizedBox(height: 1.8.hs(context).clamp(16.0, 22.0)),
                  OrdersTableView(
                    rows: state.visibleRows,
                    offset: state.offset,
                    savingByOrderId: state.savingByOrderId,
                    onRowTap: _openOrderDetailFromRow,
                    onChangeRowStatus:
                        (orderId, currentStatus, nextStatus) async {
                          await context
                              .read<OrdersTableCubit>()
                              .changeRowStatus(
                                orderId: orderId,
                                currentStatus: currentStatus,
                                nextStatus: nextStatus,
                              );
                        },
                  ),
                  SizedBox(height: 1.8.hs(context).clamp(14.0, 18.0)),
                  _OrdersPagination(state: state),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshOrdersList() async {
    final cubit = context.read<OrdersTableCubit>();
    await cubit.refresh();
  }

  Future<void> _openOrderDetailFromRow(OrdersTableRow row) async {
    final result = await context.read<OrdersCubit>().prepareOrderDetail(
      row.orderId,
      knownOrderStatus: row.orderStatus,
      allowReadyOrder: true,
      preferOrderDetailRpc: true,
    );

    if (!mounted || result.success) return;

    final message =
        result.message ?? 'No se pudo cargar el detalle del pedido.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: LocalizedText(message)));
  }
}

class _OrdersListHeader extends StatelessWidget {
  const _OrdersListHeader({
    required this.state,
    required this.searchController,
    required this.onRefresh,
  });

  final OrdersTableState state;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrdersTableCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          'Historial completo',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 0.7.hs(context).clamp(6.0, 8.0)),
        Row(
          children: [
            Expanded(
              child: LocalizedText(
                'Órdenes',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: context.tr('Refrescar'),
              onPressed: state.status == OrdersTableStatus.loading
                  ? null
                  : onRefresh,
              icon: Icon(
                state.status == OrdersTableStatus.loading
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.hs(context).clamp(4.0, 6.0)),
        LocalizedText(
          'Busca y actualiza el estado de las órdenes pagadas de esta ubicación.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.2.hs(context).clamp(10.0, 14.0)),
        SizedBox(height: 1.6.hs(context).clamp(14.0, 18.0)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: cubit.setSearchQuery,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: context.tr('Buscar por orden o cliente'),
                  suffixIcon: state.searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => cubit.setSearchQuery(''),
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            SizedBox(width: 1.ws(context).clamp(8.0, 10.0)),
            _buildControls(context, state, cubit).single,
          ],
        ),
        SizedBox(height: 2.2.hs(context).clamp(18.0, 24.0)),
      ],
    );
  }

  List<Widget> _buildControls(
    BuildContext context,
    OrdersTableState state,
    OrdersTableCubit cubit,
  ) {
    return [
      PopupMenuButton<(OrdersTableSortBy, OrdersTableSortDirection)>(
        onSelected: (value) {
          cubit.updateSort(sortBy: value.$1, sortDirection: value.$2);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: (OrdersTableSortBy.createdAt, OrdersTableSortDirection.desc),
            child: LocalizedText('Mas recientes'),
          ),
          PopupMenuItem(
            value: (OrdersTableSortBy.createdAt, OrdersTableSortDirection.asc),
            child: LocalizedText('Mas antiguas'),
          ),
          PopupMenuItem(
            value: (OrdersTableSortBy.total, OrdersTableSortDirection.desc),
            child: LocalizedText('Mayor total'),
          ),
          PopupMenuItem(
            value: (OrdersTableSortBy.total, OrdersTableSortDirection.asc),
            child: LocalizedText('Menor total'),
          ),
        ],
        child: IconButton.filledTonal(
          tooltip: context.tr('Ordenar'),
          icon: const Icon(Icons.swap_vert_rounded),
          onPressed: null,
        ),
      ),
    ];
  }
}

class _OrdersPagination extends StatelessWidget {
  const _OrdersPagination({required this.state});

  final OrdersTableState state;

  @override
  Widget build(BuildContext context) {
    final from = state.rows.isEmpty ? 0 : state.offset + 1;
    final to = state.offset + state.rows.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(2.2.ws(context).clamp(18.0, 22.0)),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 1.8.ws(context).clamp(16.0, 18.0),
          vertical: 1.4.hs(context).clamp(12.0, 14.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                state.rows.isEmpty ? 'Sin resultados' : 'Mostrando $from-$to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: state.page > 1
                  ? () => context.read<OrdersTableCubit>().goToPreviousPage()
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const LocalizedText('Anterior'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 1.ws(context).clamp(8.0, 10.0),
              ),
              child: Container(
                width: 4.hs(context).clamp(36.0, 40.0),
                height: 4.hs(context).clamp(36.0, 40.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(
                    1.4.ws(context).clamp(12.0, 14.0),
                  ),
                ),
                child: Text(
                  '${state.page}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: state.hasMore
                  ? () => context.read<OrdersTableCubit>().goToNextPage()
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const LocalizedText('Siguiente'),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersTableMessageCard extends StatelessWidget {
  const _OrdersTableMessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(2.4.ws(context).clamp(20.0, 24.0)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.82),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 2.4.ws(context).clamp(20.0, 24.0),
            offset: Offset(0, 1.2.hs(context).clamp(10.0, 12.0)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(3.ws(context).clamp(20.0, 28.0)),
        child: Column(
          children: [
            Icon(
              icon,
              size: 3.6.hs(context).clamp(32.0, 36.0),
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 1.2.hs(context).clamp(10.0, 14.0)),
            LocalizedText(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 0.8.hs(context).clamp(8.0, 10.0)),
            LocalizedText(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.6.hs(context).clamp(14.0, 18.0)),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(
                Icons.refresh_rounded,
                size: 1.8.hs(context).clamp(16.0, 18.0),
              ),
              label: LocalizedText(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 1.6.ws(context).clamp(14.0, 16.0),
        vertical: 1.2.hs(context).clamp(10.0, 12.0),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.6.ws(context).clamp(14.0, 16.0)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.82),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 1.8.hs(context).clamp(16.0, 18.0)),
          SizedBox(width: 0.8.ws(context).clamp(8.0, 10.0)),
          LocalizedText(label),
        ],
      ),
    );
  }
}
