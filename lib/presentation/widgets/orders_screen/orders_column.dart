import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'order_card_widget.dart';

class OrdersColumn extends StatelessWidget {
  const OrdersColumn({super.key, required this.sections, required this.now});

  final List<OrdersColumnSection> sections;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(1.4.ws(context).clamp(14.0, 18.0)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(1.8.ws(context).clamp(16.0, 20.0)),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < sections.length; index++) ...[
            if (index > 0) ...[Divider(height: 3.2.hs(context))],
            _OrdersSection(section: sections[index], now: now),
          ],
        ],
      ),
    );
  }
}

class OrdersColumnSection {
  const OrdersColumnSection(this.title, this.icon, this.orders);

  final String title;
  final IconData icon;
  final List<OrderSummary> orders;
}

class _OrdersSection extends StatelessWidget {
  const _OrdersSection({required this.section, required this.now});

  final OrdersColumnSection section;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  section.icon,
                  size: 2.hs(context).clamp(16.0, 20.0),
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(width: 0.8.ws(context).clamp(8.0, 10.0)),
            Expanded(
              child: LocalizedText(
                section.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Semantics(
              label: '${section.title}: ${section.orders.length}',
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 0.9.ws(context).clamp(10.0, 12.0),
                  vertical: 0.5.hs(context).clamp(5.0, 6.0),
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    1.6.ws(context).clamp(14.0, 18.0),
                  ),
                ),
                child: Text(
                  '${section.orders.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.6.hs(context)),
        ...section.orders.map((order) {
          final forwardLabel = orderBoardForwardLabel(order);

          return Padding(
            padding: EdgeInsets.only(bottom: 1.2.hs(context)),
            child: OrderCardWidget(
              order: order,
              now: now,
              onTap: () {
                context.read<OrdersCubit>().selectOrder(order.orderId);
              },
              forwardLabel: forwardLabel,
              onForwardPressed: forwardLabel == null
                  ? null
                  : () {
                      context.read<OrdersCubit>().moveOrderForward(
                        order.orderId,
                      );
                    },
              onBackwardPressed: orderBoardShowsBack(order)
                  ? () {
                      context.read<OrdersCubit>().moveOrderBackward(
                        order.orderId,
                      );
                    }
                  : null,
            ),
          );
        }),
      ],
    );
  }
}
