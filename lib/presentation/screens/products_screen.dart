import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:mediasis_dashboard_app/presentation/widgets/products/products_table_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final TextEditingController _searchController;
  bool _didRequestStageLoad = false;

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
    final selectedLocation = context
        .watch<LocationCubit>()
        .state
        .selectedLocation;
    final activeLocationId = selectedLocation?.businessLocationId;

    return BlocListener<ProductsCubit, ProductsState>(
      listenWhen: (previous, current) =>
          previous.transientMessage != current.transientMessage,
      listener: (context, state) {
        if (state.transientMessage.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: LocalizedText(state.transientMessage)),
        );
        context.read<ProductsCubit>().clearTransientMessage();
      },
      child: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          if (_searchController.text != state.searchQuery) {
            _searchController.value = TextEditingValue(
              text: state.searchQuery,
              selection: TextSelection.collapsed(
                offset: state.searchQuery.length,
              ),
            );
          }

          final shouldReloadForStageEntry =
              !_didRequestStageLoad &&
              activeLocationId != null &&
              state.status != ProductsStatus.loading;
          final shouldReloadForLocationChange =
              activeLocationId != null &&
              state.businessLocationId != activeLocationId &&
              state.status != ProductsStatus.loading;

          if (shouldReloadForStageEntry || shouldReloadForLocationChange) {
            final requestedLocationId = activeLocationId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _didRequestStageLoad = true;
              context.read<ProductsCubit>().loadProducts(
                businessLocationId: requestedLocationId,
                force: true,
              );
            });
          }

          final horizontalPadding = 4.ws(context).clamp(16.0, 40.0);

          return RefreshIndicator(
            onRefresh: () => context.read<ProductsCubit>().refresh(),
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
                    child: _ProductsHeader(
                      state: state,
                      searchController: _searchController,
                    ),
                  ),
                ),
                if (state.status == ProductsStatus.loading &&
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
                if (state.status == ProductsStatus.loading &&
                    state.rows.isEmpty) ...[
                  SizedBox(height: 2.4.hs(context).clamp(20.0, 24.0)),
                  const Center(child: CircularProgressIndicator()),
                ] else if (state.status == ProductsStatus.failure) ...[
                  SizedBox(height: 2.4.hs(context).clamp(20.0, 24.0)),
                  _ProductsMessageCard(
                    icon: Icons.error_outline_rounded,
                    title: 'No se pudieron cargar los productos',
                    subtitle: state.errorMessage,
                    actionLabel: 'Reintentar',
                    onAction: () => context.read<ProductsCubit>().refresh(),
                  ),
                ] else if (state.visibleRows.isEmpty) ...[
                  SizedBox(height: 2.4.hs(context).clamp(20.0, 24.0)),
                  _ProductsMessageCard(
                    icon: Icons.inventory_2_outlined,
                    title: state.searchQuery.trim().isEmpty
                        ? 'No hay productos para mostrar'
                        : 'No hay resultados',
                    subtitle: state.searchQuery.trim().isEmpty
                        ? 'Cuando existan productos en el catálogo, apareceran aqui.'
                        : 'Prueba con otra busqueda.',
                    actionLabel: 'Actualizar',
                    onAction: () => context.read<ProductsCubit>().refresh(),
                  ),
                ] else ...[
                  SizedBox(height: 1.8.hs(context).clamp(16.0, 22.0)),
                  ProductsTableView(
                    rows: state.visibleRows,
                    savingByProductId: state.savingByProductId,
                    expandedProductIds: state.expandedProductIds,
                    optionsByProductId: state.optionsByProductId,
                    variantsByProductId: state.variantsByProductId,
                    loadingOptionsByProductId: state.loadingOptionsByProductId,
                    savingByChoiceId: state.savingByChoiceId,
                    savingByVariantId: state.savingByVariantId,
                    onToggleVisibility: (productId, nextVisibility) async {
                      await context.read<ProductsCubit>().toggleVisibility(
                        businessLocationId:
                            selectedLocation?.businessLocationId ?? '',
                        productId: productId,
                        nextVisibility: nextVisibility,
                      );
                    },
                    onToggleOptionsPanel: (productId) {
                      context.read<ProductsCubit>().toggleOptionsPanel(
                        productId,
                      );
                    },
                    onToggleChoiceVisibility:
                        (choiceId, productId, optionId, nextVisible) {
                          context.read<ProductsCubit>().toggleChoiceVisibility(
                            choiceId: choiceId,
                            productId: productId,
                            optionId: optionId,
                            nextVisible: nextVisible,
                          );
                        },
                    onToggleVariantVisibility:
                        (productId, variantId, nextVisible) {
                          context.read<ProductsCubit>().toggleVariantVisibility(
                            productId: productId,
                            variantId: variantId,
                            nextVisible: nextVisible,
                          );
                        },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductsHeader extends StatelessWidget {
  const _ProductsHeader({required this.state, required this.searchController});

  final ProductsState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductsCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    'Catálogo actual',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 0.7.hs(context).clamp(6.0, 8.0)),
                  LocalizedText(
                    'Productos',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.tr('Refrescar'),
              onPressed: state.status == ProductsStatus.loading
                  ? null
                  : () => cubit.refresh(),
              icon: Icon(
                state.status == ProductsStatus.loading
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.hs(context).clamp(4.0, 6.0)),
        LocalizedText(
          'Revisa el catálogo y oculta productos cuando sea necesario.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.6.hs(context).clamp(14.0, 18.0)),
        TextField(
          controller: searchController,
          onChanged: cubit.setSearchQuery,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: context.tr('Buscar producto'),
            suffixIcon: state.searchQuery.isEmpty
                ? null
                : IconButton(
                    onPressed: () => cubit.setSearchQuery(''),
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ProductsMessageCard extends StatelessWidget {
  const _ProductsMessageCard({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(2.8.ws(context).clamp(24.0, 28.0)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.74),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 2.8.ws(context).clamp(24.0, 28.0),
            offset: Offset(0, 1.6.hs(context).clamp(14.0, 16.0)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 2.ws(context).clamp(18.0, 20.0),
          vertical: 2.4.hs(context).clamp(20.0, 24.0),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 3.4.hs(context).clamp(30.0, 34.0),
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 1.2.hs(context).clamp(10.0, 12.0)),
            LocalizedText(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 0.8.hs(context).clamp(6.0, 8.0)),
            LocalizedText(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.6.hs(context).clamp(14.0, 16.0)),
            OutlinedButton(
              onPressed: onAction,
              child: LocalizedText(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
