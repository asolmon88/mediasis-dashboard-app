import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:flutter/material.dart';

enum AuthenticatedStage { realtime, orders, products, settings }

class AuthenticatedStageBar extends StatelessWidget {
  const AuthenticatedStageBar({
    required this.selectedStage,
    required this.onSelected,
    required this.isPhoneLayout,
    super.key,
  });

  final AuthenticatedStage selectedStage;
  final ValueChanged<AuthenticatedStage> onSelected;
  final bool isPhoneLayout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horizontalPadding = 4.ws(context).clamp(16.0, 40.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0.8.hs(context).clamp(8.0, 12.0),
        horizontalPadding,
        1.2.hs(context).clamp(10.0, 16.0),
      ),
      child: Align(
        alignment: Alignment.center,
        child: IntrinsicWidth(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(
                3.hs(context).clamp(24.0, 999.0),
              ),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 1.8.ws(context).clamp(16.0, 18.0),
                  offset: Offset(0, 1.hs(context).clamp(8.0, 10.0)),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(0.4.ws(context).clamp(4.0, 6.0)),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StageChip(
                      label: 'Tiempo real',
                      icon: Icons.bolt_rounded,
                      selected: selectedStage == AuthenticatedStage.realtime,
                      compactColumn: isPhoneLayout,
                      onPressed: () => onSelected(AuthenticatedStage.realtime),
                    ),
                    _StageChip(
                      label: 'Órdenes',
                      icon: Icons.receipt_long_rounded,
                      selected: selectedStage == AuthenticatedStage.orders,
                      compactColumn: isPhoneLayout,
                      onPressed: () => onSelected(AuthenticatedStage.orders),
                    ),
                    _StageChip(
                      label: 'Productos',
                      icon: Icons.inventory_2_rounded,
                      selected: selectedStage == AuthenticatedStage.products,
                      compactColumn: isPhoneLayout,
                      onPressed: () => onSelected(AuthenticatedStage.products),
                    ),
                    _StageChip(
                      label: 'Configuración',
                      icon: Icons.settings_rounded,
                      selected: selectedStage == AuthenticatedStage.settings,
                      compactColumn: isPhoneLayout,
                      onPressed: () => onSelected(AuthenticatedStage.settings),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.compactColumn = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  final bool compactColumn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horizontalPadding = compactColumn
        ? 1.1.ws(context).clamp(8.0, 11.0)
        : 1.3.ws(context).clamp(14.0, 20.0);
    final verticalPadding = compactColumn
        ? 0.7.hs(context).clamp(6.0, 8.0)
        : 1.1.hs(context).clamp(10.0, 12.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 0.2.ws(context).clamp(2.0, 4.0),
      ),
      child: compactColumn
          ? TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                backgroundColor: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    3.hs(context).clamp(24.0, 999.0),
                  ),
                ),
              ),
              child: Semantics(
                button: true,
                selected: selected,
                label: context.tr(label),
                child: Icon(icon, size: 1.8.hs(context).clamp(18.0, 20.0)),
              ),
            )
          : TextButton.icon(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                backgroundColor: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    3.hs(context).clamp(24.0, 999.0),
                  ),
                ),
              ),
              icon: Icon(icon, size: 1.8.hs(context).clamp(16.0, 18.0)),
              label: Semantics(
                button: true,
                selected: selected,
                label: context.tr(label),
                child: LocalizedText(
                  label,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            ),
    );
  }
}
