import 'package:flutter/material.dart';

/// Shared sizing and visual treatment for order-card actions.
///
/// Keeping these actions in one widget prevents receipt, tracking, and pickup
/// controls from drifting apart across the board and order details views.
class OrderActionButton extends StatelessWidget {
  const OrderActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
    this.loading = false,
    this.compact = false,
    super.key,
  });

  final Widget label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool emphasized;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.primary;

    return SizedBox(
      height: compact ? 34 : 42,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: emphasized
              ? foreground.withValues(alpha: 0.06)
              : null,
          side: BorderSide(
            color: emphasized
                ? foreground.withValues(alpha: 0.25)
                : theme.colorScheme.outline,
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
          minimumSize: Size(0, compact ? 34 : 42),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle:
              (compact
                      ? theme.textTheme.labelSmall
                      : theme.textTheme.labelLarge)
                  ?.copyWith(
                    fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                  ),
        ),
        icon: loading
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: compact ? 15 : 18),
        label: label,
      ),
    );
  }
}
