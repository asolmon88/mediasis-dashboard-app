import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrdersErrorView extends StatelessWidget {
  const OrdersErrorView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationState = context.watch<LocationCubit>().state;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 50.ws(context).clamp(320.0, 560.0),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.25),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.ws(context)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 5.hs(context).clamp(42.0, 52.0),
                  color: theme.colorScheme.error,
                ),
                SizedBox(height: 2.hs(context)),
                LocalizedText(
                  'No se pudieron cargar los pedidos',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.5.hs(context)),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 3.hs(context)),
                FilledButton(
                  onPressed: locationState.selectedLocation == null
                      ? null
                      : () {
                          context.read<OrdersCubit>().loadOrders(
                            locationState.selectedLocation!.businessLocationId,
                          );
                        },
                  child: const LocalizedText('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
