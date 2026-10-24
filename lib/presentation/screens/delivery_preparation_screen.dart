import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:mediasis_dashboard_app/presentation/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeliveryPreparationScreen extends StatefulWidget {
  const DeliveryPreparationScreen({super.key});

  @override
  State<DeliveryPreparationScreen> createState() =>
      _DeliveryPreparationScreenState();
}

class _DeliveryPreparationScreenState extends State<DeliveryPreparationScreen> {
  bool _didRequestInitialLoad = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = context
        .watch<LocationCubit>()
        .state
        .selectedLocation;
    final activeLocationId = selectedLocation?.businessLocationId ?? '';
    final isPhoneLayout = isCompactWindow(context);

    return Scaffold(
      appBar: AppBar(title: const LocalizedText('Tiempo de preparación')),
      body: BlocListener<DeliveryPreparationCubit, DeliveryPreparationState>(
        listenWhen: (previous, current) =>
            previous.transientMessage != current.transientMessage,
        listener: (context, state) {
          if (state.transientMessage.isEmpty) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: LocalizedText(state.transientMessage)),
          );
          context.read<DeliveryPreparationCubit>().clearTransientMessage();
        },
        child: BlocBuilder<DeliveryPreparationCubit, DeliveryPreparationState>(
          builder: (context, state) {
            final shouldRequestInitialLoad =
                !_didRequestInitialLoad &&
                state.status != DeliveryPreparationStatus.loading;
            final shouldReloadForLocationChange =
                state.businessLocationId != activeLocationId &&
                state.status != DeliveryPreparationStatus.loading;

            if (shouldRequestInitialLoad || shouldReloadForLocationChange) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _didRequestInitialLoad = true;
                context.read<DeliveryPreparationCubit>().loadForLocation(
                  businessLocationId: activeLocationId,
                  force: true,
                );
              });
            }

            final horizontalPadding = 4.ws(context).clamp(16.0, 40.0);

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<DeliveryPreparationCubit>().refresh(),
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  1.2.hs(context).clamp(10.0, 14.0),
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
                      padding: EdgeInsets.all(
                        2.2.ws(context).clamp(18.0, 26.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText(
                            'Tiempo de preparación',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                          ),
                          SizedBox(height: 0.7.hs(context).clamp(6.0, 8.0)),
                          LocalizedText(
                            'Métodos de entrega por ubicación',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 0.5.hs(context).clamp(4.0, 6.0)),
                          LocalizedText(
                            'Configura el tiempo estimado de preparación para cada servicio del local activo.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          SizedBox(height: 1.2.hs(context).clamp(10.0, 14.0)),
                          if (selectedLocation != null)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  2.4.hs(context).clamp(18.0, 999.0),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 1.4.ws(context).clamp(12.0, 14.0),
                                  vertical: 0.9.hs(context).clamp(8.0, 9.0),
                                ),
                                child: Text(
                                  '${context.tr('Ubicación')}: ${selectedLocation.shortName}',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 1.8.hs(context).clamp(16.0, 22.0)),
                  if (state.status == DeliveryPreparationStatus.loading &&
                      state.rows.isEmpty) ...[
                    const Center(child: CircularProgressIndicator()),
                  ] else if (state.status ==
                      DeliveryPreparationStatus.failure) ...[
                    _DeliveryPreparationMessageCard(
                      icon: Icons.error_outline_rounded,
                      title: 'No se pudieron cargar los métodos de delivery',
                      subtitle: state.errorMessage,
                      actionLabel: 'Reintentar',
                      onAction: () =>
                          context.read<DeliveryPreparationCubit>().refresh(),
                    ),
                  ] else if (state.status ==
                      DeliveryPreparationStatus.empty) ...[
                    _DeliveryPreparationMessageCard(
                      icon: Icons.local_shipping_outlined,
                      title: 'No hay métodos de delivery',
                      subtitle:
                          'Cuando existan métodos de delivery configurados, aparecerán aquí.',
                      actionLabel: 'Actualizar',
                      onAction: () =>
                          context.read<DeliveryPreparationCubit>().refresh(),
                    ),
                  ] else ...[
                    DeliveryPreparationManagementSection(
                      isPhoneLayout: isPhoneLayout,
                      rows: state.rows,
                      prepMinutesByRow: state.prepMinutesByRow,
                      editingMinutesByRow: state.editingMinutesByRow,
                      pendingRows: state.pendingRows,
                      editingRowId: state.editingRowId,
                      enabled: activeLocationId.isNotEmpty,
                      locationName: selectedLocation?.shortName,
                      onRefresh: () =>
                          context.read<DeliveryPreparationCubit>().refresh(),
                      onEditRequested: (rowId) => context
                          .read<DeliveryPreparationCubit>()
                          .openQuickEdit(rowId),
                      onPresetSelected: (rowId, minutes) => context
                          .read<DeliveryPreparationCubit>()
                          .setEditingMinutes(rowId, minutes),
                      onMinutesChanged: (rowId, rawValue) {
                        if (rawValue.trim().isEmpty) {
                          context
                              .read<DeliveryPreparationCubit>()
                              .setEditingMinutes(rowId, 0);
                          return;
                        }
                        final next = int.tryParse(rawValue);
                        if (next != null) {
                          context
                              .read<DeliveryPreparationCubit>()
                              .setEditingMinutes(rowId, next);
                        }
                      },
                      onSaveRequested: (rowId) => context
                          .read<DeliveryPreparationCubit>()
                          .saveQuickEdit(rowId),
                      onCancelRequested: (rowId) => context
                          .read<DeliveryPreparationCubit>()
                          .cancelQuickEdit(rowId),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DeliveryPreparationMessageCard extends StatelessWidget {
  const _DeliveryPreparationMessageCard({
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
            FilledButton.tonal(
              onPressed: onAction,
              child: LocalizedText(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
