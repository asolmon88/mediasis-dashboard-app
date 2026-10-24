import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:flutter/material.dart';

class OrdersLoadingView extends StatelessWidget {
  const OrdersLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 50.ws(context).clamp(320.0, 560.0),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.ws(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LoadingBlock(
                width: 32.ws(context).clamp(180.0, 300.0),
                height: 24,
              ),
              SizedBox(height: 1.2.hs(context)),
              _LoadingBlock(
                width: 44.ws(context).clamp(240.0, 420.0),
                height: 16,
              ),
              SizedBox(height: 0.8.hs(context)),
              _LoadingBlock(
                width: 38.ws(context).clamp(220.0, 360.0),
                height: 16,
              ),
              SizedBox(height: 2.4.hs(context)),
              LocalizedText(
                'Cargando pedidos en tiempo real...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
