import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/presentation/market_context.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/presentation/widgets/products_list_formatters.dart';
import 'package:flutter/material.dart';

typedef ProductVisibilityChanged =
    Future<void> Function(String productId, bool nextVisibility);
typedef ProductOptionsPanelToggled = void Function(String productId);
typedef ChoiceVisibilityChanged =
    void Function(
      String choiceId,
      String productId,
      String optionId,
      bool nextVisible,
    );
typedef VariantVisibilityChanged =
    void Function(String productId, String variantId, bool nextVisible);

class ProductsTableView extends StatelessWidget {
  const ProductsTableView({
    required this.rows,
    required this.savingByProductId,
    required this.onToggleVisibility,
    required this.expandedProductIds,
    required this.optionsByProductId,
    required this.variantsByProductId,
    required this.loadingOptionsByProductId,
    required this.savingByChoiceId,
    required this.savingByVariantId,
    required this.onToggleOptionsPanel,
    required this.onToggleChoiceVisibility,
    required this.onToggleVariantVisibility,
    super.key,
  });

  final List<ProductTableRow> rows;
  final Map<String, bool> savingByProductId;
  final ProductVisibilityChanged onToggleVisibility;
  final Set<String> expandedProductIds;
  final Map<String, List<ProductOptionRow>> optionsByProductId;
  final Map<String, List<ProductVariantRow>> variantsByProductId;
  final Map<String, bool> loadingOptionsByProductId;
  final Map<String, bool> savingByChoiceId;
  final Map<String, bool> savingByVariantId;
  final ProductOptionsPanelToggled onToggleOptionsPanel;
  final ChoiceVisibilityChanged onToggleChoiceVisibility;
  final VariantVisibilityChanged onToggleVariantVisibility;

  @override
  Widget build(BuildContext context) {
    final isPhoneLayout = !isWideWindow(context);

    return isPhoneLayout
        ? _ProductsCardsList(
            rows: rows,
            savingByProductId: savingByProductId,
            onToggleVisibility: onToggleVisibility,
            expandedProductIds: expandedProductIds,
            optionsByProductId: optionsByProductId,
            variantsByProductId: variantsByProductId,
            loadingOptionsByProductId: loadingOptionsByProductId,
            savingByChoiceId: savingByChoiceId,
            savingByVariantId: savingByVariantId,
            onToggleOptionsPanel: onToggleOptionsPanel,
            onToggleChoiceVisibility: onToggleChoiceVisibility,
            onToggleVariantVisibility: onToggleVariantVisibility,
          )
        : _ProductsDesktopTable(
            rows: rows,
            savingByProductId: savingByProductId,
            onToggleVisibility: onToggleVisibility,
            expandedProductIds: expandedProductIds,
            optionsByProductId: optionsByProductId,
            variantsByProductId: variantsByProductId,
            loadingOptionsByProductId: loadingOptionsByProductId,
            savingByChoiceId: savingByChoiceId,
            savingByVariantId: savingByVariantId,
            onToggleOptionsPanel: onToggleOptionsPanel,
            onToggleChoiceVisibility: onToggleChoiceVisibility,
            onToggleVariantVisibility: onToggleVariantVisibility,
          );
  }
}

// ─── Desktop ─────────────────────────────────────────────────────────────────

class _ProductsDesktopTable extends StatelessWidget {
  const _ProductsDesktopTable({
    required this.rows,
    required this.savingByProductId,
    required this.onToggleVisibility,
    required this.expandedProductIds,
    required this.optionsByProductId,
    required this.variantsByProductId,
    required this.loadingOptionsByProductId,
    required this.savingByChoiceId,
    required this.savingByVariantId,
    required this.onToggleOptionsPanel,
    required this.onToggleChoiceVisibility,
    required this.onToggleVariantVisibility,
  });

  final List<ProductTableRow> rows;
  final Map<String, bool> savingByProductId;
  final ProductVisibilityChanged onToggleVisibility;
  final Set<String> expandedProductIds;
  final Map<String, List<ProductOptionRow>> optionsByProductId;
  final Map<String, List<ProductVariantRow>> variantsByProductId;
  final Map<String, bool> loadingOptionsByProductId;
  final Map<String, bool> savingByChoiceId;
  final Map<String, bool> savingByVariantId;
  final ProductOptionsPanelToggled onToggleOptionsPanel;
  final ChoiceVisibilityChanged onToggleChoiceVisibility;
  final VariantVisibilityChanged onToggleVariantVisibility;

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
              final isExpanded = expandedProductIds.contains(row.productId);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: 1.hs(context).clamp(8.0, 10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DesktopDataRow(
                      row: row,
                      saving: savingByProductId[row.productId] == true,
                      isExpanded: isExpanded,
                      onToggleVisibility: onToggleVisibility,
                      onToggleOptionsPanel: onToggleOptionsPanel,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: isExpanded
                          ? Padding(
                              padding: EdgeInsets.only(
                                top: 0.6.hs(context).clamp(4.0, 6.0),
                              ),
                              child: _OptionsPanel(
                                productId: row.productId,
                                productVisible: row.visibility,
                                loading:
                                    loadingOptionsByProductId[row.productId] ==
                                    true,
                                options:
                                    optionsByProductId[row.productId] ??
                                    const [],
                                variants:
                                    variantsByProductId[row.productId] ??
                                    const [],
                                savingByChoiceId: savingByChoiceId,
                                savingByVariantId: savingByVariantId,
                                onToggleChoiceVisibility:
                                    onToggleChoiceVisibility,
                                onToggleVariantVisibility:
                                    onToggleVariantVisibility,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
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
          Expanded(flex: 5, child: LocalizedText('Producto', style: textStyle)),
          Expanded(flex: 2, child: LocalizedText('Precio', style: textStyle)),
          Expanded(flex: 2, child: LocalizedText('Estado', style: textStyle)),
          Expanded(flex: 2, child: LocalizedText('Gestión', style: textStyle)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: LocalizedText('Ocultar', style: textStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopDataRow extends StatelessWidget {
  const _DesktopDataRow({
    required this.row,
    required this.saving,
    required this.isExpanded,
    required this.onToggleVisibility,
    required this.onToggleOptionsPanel,
  });

  final ProductTableRow row;
  final bool saving;
  final bool isExpanded;
  final ProductVisibilityChanged onToggleVisibility;
  final ProductOptionsPanelToggled onToggleOptionsPanel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 2.ws(context).clamp(18.0, 20.0),
        vertical: 1.6.hs(context).clamp(14.0, 16.0),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(2.ws(context).clamp(18.0, 20.0)),
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
            flex: 5,
            child: Row(
              children: [
                _ProductThumbnail(
                  imageUrl: row.images.firstOrNull,
                  name: row.name,
                ),
                SizedBox(width: 1.4.ws(context).clamp(12.0, 14.0)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (row.categories.isNotEmpty) ...[
                        SizedBox(height: 0.4.hs(context).clamp(4.0, 6.0)),
                        Text(
                          row.categories.first,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatProductPrice(row.price, market: context.market),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _VisibilityBadge(visibility: row.visibility),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextButton.icon(
              onPressed: () => onToggleOptionsPanel(row.productId),
              icon: Icon(
                isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 1.8.hs(context).clamp(16.0, 18.0),
              ),
              label: LocalizedText(
                isExpanded ? 'Ocultar' : 'Administrar',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.ws(context).clamp(8.0, 10.0),
                  vertical: 0.6.hs(context).clamp(4.0, 6.0),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Switch.adaptive(
                value: row.visibility,
                onChanged: saving
                    ? null
                    : (value) => onToggleVisibility(row.productId, value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile ──────────────────────────────────────────────────────────────────

class _ProductsCardsList extends StatelessWidget {
  const _ProductsCardsList({
    required this.rows,
    required this.savingByProductId,
    required this.onToggleVisibility,
    required this.expandedProductIds,
    required this.optionsByProductId,
    required this.variantsByProductId,
    required this.loadingOptionsByProductId,
    required this.savingByChoiceId,
    required this.savingByVariantId,
    required this.onToggleOptionsPanel,
    required this.onToggleChoiceVisibility,
    required this.onToggleVariantVisibility,
  });

  final List<ProductTableRow> rows;
  final Map<String, bool> savingByProductId;
  final ProductVisibilityChanged onToggleVisibility;
  final Set<String> expandedProductIds;
  final Map<String, List<ProductOptionRow>> optionsByProductId;
  final Map<String, List<ProductVariantRow>> variantsByProductId;
  final Map<String, bool> loadingOptionsByProductId;
  final Map<String, bool> savingByChoiceId;
  final Map<String, bool> savingByVariantId;
  final ProductOptionsPanelToggled onToggleOptionsPanel;
  final ChoiceVisibilityChanged onToggleChoiceVisibility;
  final VariantVisibilityChanged onToggleVariantVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map((row) {
            final saving = savingByProductId[row.productId] == true;
            final isExpanded = expandedProductIds.contains(row.productId);

            return Padding(
              padding: EdgeInsets.only(
                bottom: 1.2.hs(context).clamp(10.0, 14.0),
              ),
              child: Container(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProductThumbnail(
                            imageUrl: row.images.firstOrNull,
                            name: row.name,
                            size: 5.8.hs(context).clamp(52.0, 58.0),
                          ),
                          SizedBox(width: 1.2.ws(context).clamp(10.0, 12.0)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.name,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                SizedBox(
                                  height: 0.4.hs(context).clamp(4.0, 6.0),
                                ),
                                Text(
                                  formatProductPrice(
                                    row.price,
                                    market: context.market,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (row.categories.isNotEmpty) ...[
                                  SizedBox(
                                    height: 0.4.hs(context).clamp(4.0, 6.0),
                                  ),
                                  Text(
                                    row.categories.first,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.4.hs(context).clamp(12.0, 14.0)),
                      Row(
                        children: [
                          _VisibilityBadge(visibility: row.visibility),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () =>
                                onToggleOptionsPanel(row.productId),
                            icon: Icon(
                              isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 1.6.hs(context).clamp(14.0, 16.0),
                            ),
                            label: LocalizedText(
                              isExpanded ? 'Ocultar' : 'Administrar',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 0.8.ws(context).clamp(6.0, 8.0),
                                vertical: 0.4.hs(context).clamp(3.0, 4.0),
                              ),
                            ),
                          ),
                          SizedBox(width: 0.4.ws(context).clamp(4.0, 6.0)),
                          LocalizedText(
                            'Visible',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(width: 0.8.ws(context).clamp(8.0, 10.0)),
                          Switch.adaptive(
                            value: row.visibility,
                            onChanged: saving
                                ? null
                                : (value) =>
                                      onToggleVisibility(row.productId, value),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: isExpanded
                            ? Padding(
                                padding: EdgeInsets.only(
                                  top: 1.2.hs(context).clamp(10.0, 12.0),
                                ),
                                child: _OptionsPanel(
                                  productId: row.productId,
                                  productVisible: row.visibility,
                                  loading:
                                      loadingOptionsByProductId[row
                                          .productId] ==
                                      true,
                                  options:
                                      optionsByProductId[row.productId] ??
                                      const [],
                                  variants:
                                      variantsByProductId[row.productId] ??
                                      const [],
                                  savingByChoiceId: savingByChoiceId,
                                  savingByVariantId: savingByVariantId,
                                  onToggleChoiceVisibility:
                                      onToggleChoiceVisibility,
                                  onToggleVariantVisibility:
                                      onToggleVariantVisibility,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

// ─── Options Panel ────────────────────────────────────────────────────────────

class _OptionsPanel extends StatelessWidget {
  const _OptionsPanel({
    required this.productId,
    required this.productVisible,
    required this.loading,
    required this.options,
    required this.variants,
    required this.savingByChoiceId,
    required this.savingByVariantId,
    required this.onToggleChoiceVisibility,
    required this.onToggleVariantVisibility,
  });

  final String productId;
  final bool productVisible;
  final bool loading;
  final List<ProductOptionRow> options;
  final List<ProductVariantRow> variants;
  final Map<String, bool> savingByChoiceId;
  final Map<String, bool> savingByVariantId;
  final ChoiceVisibilityChanged onToggleChoiceVisibility;
  final VariantVisibilityChanged onToggleVariantVisibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(1.8.ws(context).clamp(14.0, 18.0)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(1.4.ws(context).clamp(12.0, 14.0)),
        child: loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            : variants.isEmpty && options.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 1.6.hs(context).clamp(14.0, 16.0),
                ),
                child: Center(
                  child: LocalizedText(
                    'Este producto no tiene variantes u opciones configuradas.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (variants.isNotEmpty)
                    _VariantsList(
                      productId: productId,
                      productVisible: productVisible,
                      variants: variants,
                      savingByVariantId: savingByVariantId,
                      onToggleVariantVisibility: onToggleVariantVisibility,
                    ),
                  if (variants.isNotEmpty && options.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 1.2.hs(context).clamp(10.0, 14.0),
                      ),
                      child: Divider(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  if (options.isNotEmpty) ...[
                    LocalizedText(
                      'Opciones',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 1.hs(context).clamp(8.0, 10.0)),
                    _OptionsList(
                      productId: productId,
                      options: options,
                      savingByChoiceId: savingByChoiceId,
                      onToggleChoiceVisibility: onToggleChoiceVisibility,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _VariantsList extends StatelessWidget {
  const _VariantsList({
    required this.productId,
    required this.productVisible,
    required this.variants,
    required this.savingByVariantId,
    required this.onToggleVariantVisibility,
  });

  final String productId;
  final bool productVisible;
  final List<ProductVariantRow> variants;
  final Map<String, bool> savingByVariantId;
  final VariantVisibilityChanged onToggleVariantVisibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          'Variantes',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 0.3.hs(context).clamp(3.0, 4.0)),
        Text(
          productVisible
              ? 'Disponibilidad para esta ubicacion'
              : 'Activa el producto para administrar sus variantes.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.hs(context).clamp(8.0, 10.0)),
        ...variants.map(
          (variant) => Padding(
            padding: EdgeInsets.only(bottom: 0.7.hs(context).clamp(6.0, 8.0)),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 1.2.ws(context).clamp(10.0, 14.0),
                vertical: 0.8.hs(context).clamp(8.0, 10.0),
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.42,
                ),
                borderRadius: BorderRadius.circular(
                  1.4.ws(context).clamp(12.0, 14.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 0.2.hs(context).clamp(2.0, 3.0)),
                        Text(
                          formatProductPrice(
                            variant.price,
                            market: context.market,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 1.ws(context).clamp(8.0, 12.0)),
                  Text(
                    variant.visibleAtLocation ? 'Visible' : 'Oculta',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 0.8.ws(context).clamp(8.0, 10.0)),
                  Switch.adaptive(
                    value: variant.visibleAtLocation,
                    onChanged:
                        !productVisible ||
                            savingByVariantId[variant.productVariantId] == true
                        ? null
                        : (value) => onToggleVariantVisibility(
                            productId,
                            variant.productVariantId,
                            value,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionsList extends StatelessWidget {
  const _OptionsList({
    required this.productId,
    required this.options,
    required this.savingByChoiceId,
    required this.onToggleChoiceVisibility,
  });

  final String productId;
  final List<ProductOptionRow> options;
  final Map<String, bool> savingByChoiceId;
  final ChoiceVisibilityChanged onToggleChoiceVisibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kinds = options.map((o) => o.groupKind).toSet().toList();
    final showGroupHeaders = kinds.length > 1;

    final widgets = <Widget>[];
    String? lastKind;

    for (final option in options) {
      if (showGroupHeaders && option.groupKind != lastKind) {
        if (widgets.isNotEmpty) {
          widgets.add(SizedBox(height: 1.2.hs(context).clamp(10.0, 12.0)));
        }
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 0.6.hs(context).clamp(4.0, 6.0)),
            child: Text(
              _groupKindLabel(option.groupKind),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        );
        lastKind = option.groupKind;
      }

      widgets.add(
        _OptionSection(
          option: option,
          productId: productId,
          savingByChoiceId: savingByChoiceId,
          onToggleChoiceVisibility: onToggleChoiceVisibility,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  String _groupKindLabel(String kind) {
    switch (kind) {
      case 'general':
        return 'GENERAL';
      case 'side':
        return 'ACOMPAÑAMIENTOS';
      case 'extra':
        return 'EXTRAS';
      default:
        return kind.toUpperCase();
    }
  }
}

class _OptionSection extends StatelessWidget {
  const _OptionSection({
    required this.option,
    required this.productId,
    required this.savingByChoiceId,
    required this.onToggleChoiceVisibility,
  });

  final ProductOptionRow option;
  final String productId;
  final Map<String, bool> savingByChoiceId;
  final ChoiceVisibilityChanged onToggleChoiceVisibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.hs(context).clamp(8.0, 10.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option header (read-only)
          Row(
            children: [
              Expanded(
                child: Text(
                  option.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 0.7.ws(context).clamp(6.0, 8.0),
                  vertical: 0.2.hs(context).clamp(2.0, 3.0),
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.7,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  option.type,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (option.choices.isEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 0.4.hs(context).clamp(3.0, 4.0),
                left: 1.ws(context).clamp(8.0, 10.0),
              ),
              child: LocalizedText(
                'Sin elecciones configuradas.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(
                top: 0.4.hs(context).clamp(3.0, 4.0),
                left: 1.ws(context).clamp(8.0, 10.0),
              ),
              child: Column(
                children: option.choices
                    .map(
                      (choice) => _ChoiceRow(
                        choice: choice,
                        productId: productId,
                        optionId: option.productOptionId,
                        saving:
                            savingByChoiceId[choice.productOptionChoiceId] ==
                            true,
                        onToggleChoiceVisibility: onToggleChoiceVisibility,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.choice,
    required this.productId,
    required this.optionId,
    required this.saving,
    required this.onToggleChoiceVisibility,
  });

  final ProductOptionChoiceRow choice;
  final String productId;
  final String optionId;
  final bool saving;
  final ChoiceVisibilityChanged onToggleChoiceVisibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.4.hs(context).clamp(3.0, 4.0)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  choice.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (choice.price > 0)
                  Text(
                    formatProductPrice(choice.price, market: context.market),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (saving)
            Padding(
              padding: EdgeInsets.only(right: 0.8.ws(context).clamp(6.0, 8.0)),
              child: SizedBox(
                width: 1.4.ws(context).clamp(12.0, 14.0),
                height: 1.4.ws(context).clamp(12.0, 14.0),
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Switch.adaptive(
            value: choice.visibleAtLocation,
            onChanged: saving
                ? null
                : (value) => onToggleChoiceVisibility(
                    choice.productOptionChoiceId,
                    productId,
                    optionId,
                    value,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({
    required this.imageUrl,
    required this.name,
    this.size = 52,
  });

  final String? imageUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.65,
        ),
        borderRadius: BorderRadius.circular(1.6.ws(context).clamp(14.0, 16.0)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null || imageUrl!.trim().isEmpty
          ? Icon(
              Icons.fastfood_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: size * 0.42,
            )
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.fastfood_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: size * 0.42,
              ),
            ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({required this.visibility});

  final bool visibility;

  @override
  Widget build(BuildContext context) {
    final isVisible = visibility;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 1.1.ws(context).clamp(10.0, 11.0),
        vertical: 0.8.hs(context).clamp(7.0, 8.0),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.2.hs(context).clamp(16.0, 999.0)),
        color: (isVisible ? Colors.green : Colors.grey).withValues(alpha: 0.10),
        border: Border.all(
          color: (isVisible ? Colors.green : Colors.grey).withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Text(
        mapProductVisibilityToSpanish(visibility).toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isVisible ? Colors.green.shade700 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
