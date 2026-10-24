import 'dart:math' as math;

import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:flutter/material.dart';

class OrdersEmptyView extends StatelessWidget {
  const OrdersEmptyView({
    super.key,
    this.locationName,
    this.onRefresh,
    this.onChangeLocation,
  });

  final String? locationName;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onChangeLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 6.ws(context).clamp(20.0, 72.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (locationName != null || onChangeLocation != null) ...[
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 0.9.ws(context).clamp(8.0, 12.0),
                runSpacing: 0.9.hs(context).clamp(8.0, 10.0),
                children: [
                  if (locationName != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.ws(context).clamp(10.0, 14.0),
                        vertical: 0.8.hs(context).clamp(7.0, 9.0),
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          1.2.ws(context).clamp(10.0, 14.0),
                        ),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: LocalizedText(
                        'Ubicación: $locationName',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (onChangeLocation != null)
                    OutlinedButton(
                      onPressed: onChangeLocation,
                      child: const LocalizedText('Cambiar'),
                    ),
                ],
              ),
              SizedBox(height: 2.2.hs(context)),
            ],
            Icon(
              Icons.inbox_outlined,
              size: 5.hs(context).clamp(42.0, 52.0),
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.hs(context)),
            LocalizedText(
              'No hay pedidos activos',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.5.hs(context)),
            Text(
              locationName == null
                  ? 'Cuando entren pedidos elegibles, apareceran aqui.'
                  : 'Cuando entren pedidos elegibles en $locationName, apareceran aqui.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              SizedBox(height: 2.4.hs(context)),
              FilledButton.icon(
                onPressed: () => onRefresh!.call(),
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 1.8.hs(context).clamp(16.0, 18.0),
                ),
                label: const LocalizedText('Actualizar'),
              ),
            ],
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = isCompactWindow(context);
        final horizontalPadding = compact
            ? 16.0
            : (constraints.maxWidth * 0.035).clamp(24.0, 56.0);
        final verticalPadding = compact ? 12.0 : 20.0;
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - (horizontalPadding * 2),
        );
        final panelWidth = math.min(availableWidth, compact ? 720.0 : 1200.0);
        final viewportHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final panelHeight = math.max(
          viewportHeight - (verticalPadding * 2),
          compact ? 420.0 : 520.0,
        );
        final content = Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: panelWidth, height: panelHeight, child: panel),
        );

        if (onRefresh == null) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: content,
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh!,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            children: [content],
          ),
        );
      },
    );
  }
}
