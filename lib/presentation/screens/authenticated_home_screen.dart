import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:mediasis_dashboard_app/presentation/screens.dart';
import 'package:mediasis_dashboard_app/presentation/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthenticatedHomeScreen extends StatefulWidget {
  const AuthenticatedHomeScreen({super.key});

  @override
  State<AuthenticatedHomeScreen> createState() =>
      _AuthenticatedHomeScreenState();
}

class _AuthenticatedHomeScreenState extends State<AuthenticatedHomeScreen> {
  AuthenticatedStage _selectedStage = AuthenticatedStage.realtime;
  bool _detailDialogOpen = false;
  bool _permissionDialogOpen = false;
  bool _processingPushIntent = false;
  bool _initialPushSyncScheduled = false;
  late final AppLifecycleListener _marketLifecycle;

  @override
  void initState() {
    super.initState();
    _marketLifecycle = AppLifecycleListener(
      onResume: () async {
        await context.read<LocationCubit>().refreshMarket();
        if (!mounted) return;
        final state = context.read<LocationCubit>().state;
        if (state.status == LocationStatus.ready &&
            state.selectedLocation != null) {
          await context.read<StoreAvailabilityCubit>().loadForLocation(
            state.selectedLocation!.businessLocationId,
            market: state.market,
            force: true,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _marketLifecycle.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialPushSyncScheduled) return;
    _initialPushSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handlePushState(context.read<PushNotificationsCubit>().state);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBarHeight = 8.hs(context).clamp(60.0, 76.0);
    final isPrinting = context.select<PrintingCubit, bool>(
      (cubit) => cubit.state.status == PrintingStatus.printing,
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<OrdersCubit, OrdersState>(
          listenWhen: (previous, current) =>
              previous.selectedOrderId != current.selectedOrderId ||
              previous.status != current.status ||
              previous.businessLocationId != current.businessLocationId,
          listener: (context, state) {
            _syncDetailSheet(state);
            _processPendingPushIntent();
          },
        ),
        BlocListener<PushNotificationsCubit, PushNotificationsState>(
          listener: (context, state) => _handlePushState(state),
        ),
        BlocListener<PrintingCubit, PrintingState>(
          listenWhen: (previous, current) =>
              previous.transientMessage != current.transientMessage &&
              current.transientMessage.isNotEmpty,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: LocalizedText(state.transientMessage)),
            );
            context.read<PrintingCubit>().clearTransientMessage();
          },
        ),
      ],
      child: BlocBuilder<OrdersCubit, OrdersState>(
        buildWhen: (previous, current) =>
            previous.pendingIncomingAlertCount !=
                current.pendingIncomingAlertCount ||
            previous.selectedOrderId != current.selectedOrderId ||
            previous.status != current.status ||
            previous.orders != current.orders ||
            previous.ordersRaw != current.ordersRaw,
        builder: (context, state) {
          return Stack(
            children: [
              Scaffold(
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(appBarHeight),
                  child: AuthenticatedAppBar(toolbarHeight: appBarHeight),
                ),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    final isPhoneLayout = isCompactWindow(context);

                    return Column(
                      children: [
                        AuthenticatedStageBar(
                          selectedStage: _selectedStage,
                          isPhoneLayout: isPhoneLayout,
                          onSelected: (stage) {
                            setState(() {
                              _selectedStage = stage;
                            });
                          },
                        ),
                        AuthenticatedLocationContext(
                          locationName: context
                              .watch<LocationCubit>()
                              .state
                              .selectedLocation
                              ?.shortName,
                          onTap: () => context
                              .read<LocationCubit>()
                              .showLocationSelector(),
                        ),
                        Expanded(
                          child: switch (_selectedStage) {
                            AuthenticatedStage.realtime => const OrdersScreen(),
                            AuthenticatedStage.orders =>
                              const OrdersListScreen(),
                            AuthenticatedStage.products =>
                              const ProductsScreen(),
                            AuthenticatedStage.settings =>
                              const SettingsPlaceholderScreen(),
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (state.pendingIncomingAlertCount > 0)
                Positioned.fill(child: _buildIncomingOrderOverlay(state)),
              if (isPrinting)
                Positioned(
                  top: appBarHeight + 12,
                  left: 16,
                  right: 16,
                  child: const _PrintingProgressBanner(),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handlePushState(PushNotificationsState state) {
    if (state.shouldShowPermissionExplanation) {
      _showNotificationPermissionExplanation();
    }
    _processPendingPushIntent();
  }

  Future<void> _showNotificationPermissionExplanation() async {
    if (_permissionDialogOpen || !mounted) return;
    _permissionDialogOpen = true;

    final enable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.notifications_active_rounded,
          color: Theme.of(dialogContext).colorScheme.secondary,
          size: 42,
        ),
        title: const LocalizedText(
          'Activa las alertas de pedidos',
          textAlign: TextAlign.center,
        ),
        content: const LocalizedText(
          'Te avisaremos cuando llegue un pedido nuevo, incluso si la app '
          'está en segundo plano.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const LocalizedText('Ahora no'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.notifications_rounded),
            label: const LocalizedText('Activar'),
          ),
        ],
      ),
    );

    _permissionDialogOpen = false;
    if (!mounted) return;

    if (enable == true) {
      await context
          .read<PushNotificationsCubit>()
          .requestPermissionFromExplanation();
    } else {
      await context
          .read<PushNotificationsCubit>()
          .dismissPermissionExplanation();
    }
  }

  Future<void> _processPendingPushIntent() async {
    if (_processingPushIntent || !mounted) return;

    final pushCubit = context.read<PushNotificationsCubit>();
    if (pushCubit.state.pendingIntents.isEmpty) return;

    final intent = pushCubit.state.pendingIntents.first;
    final locationState = context.read<LocationCubit>().state;
    final targetLocation = locationState.locations
        .where(
          (location) =>
              location.businessLocationId == intent.businessLocationId,
        )
        .firstOrNull;

    if (targetLocation == null) {
      pushCubit.consumeIntent(intent);
      if (intent.source == PushNotificationIntentSource.click) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText(
              'No tienes acceso al local de esta notificación.',
            ),
          ),
        );
      }
      return;
    }

    final selectedLocationId =
        locationState.selectedLocation?.businessLocationId;
    if (intent.source == PushNotificationIntentSource.foreground &&
        selectedLocationId != intent.businessLocationId) {
      pushCubit.consumeIntent(intent);
      return;
    }

    if (selectedLocationId != intent.businessLocationId) {
      _processingPushIntent = true;
      setState(() => _selectedStage = AuthenticatedStage.realtime);
      try {
        await context.read<LocationCubit>().selectLocation(targetLocation);
      } finally {
        _processingPushIntent = false;
      }
      return;
    }

    final ordersState = context.read<OrdersCubit>().state;
    if (ordersState.businessLocationId != intent.businessLocationId ||
        ordersState.status == OrdersStatus.loading ||
        ordersState.status == OrdersStatus.initial) {
      return;
    }

    _processingPushIntent = true;
    if (intent.source == PushNotificationIntentSource.click) {
      setState(() => _selectedStage = AuthenticatedStage.realtime);
    }

    final result = await context
        .read<OrdersCubit>()
        .handleIncomingOrderNotification(
          orderId: intent.orderId,
          businessLocationId: intent.businessLocationId,
          forceAlert: intent.source == PushNotificationIntentSource.click,
        );

    if (!mounted) return;
    pushCubit.consumeIntent(intent);
    _processingPushIntent = false;

    if (!result.success &&
        intent.source == PushNotificationIntentSource.click) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'No se pudo abrir el pedido.'),
        ),
      );
    }

    if (pushCubit.state.pendingIntents.isNotEmpty) {
      _processPendingPushIntent();
    }
  }

  Widget _buildIncomingOrderOverlay(OrdersState state) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<OrdersCubit>().acknowledgeIncomingOrders();
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: ColoredBox(
          color: theme.colorScheme.secondary,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${state.pendingIncomingAlertCount}',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.onSecondary,
                  fontSize: 220,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  OrderRealtimeOrder? _findSelectedRawOrder(OrdersState state) {
    final selectedOrderId = state.selectedOrderId;
    if (selectedOrderId == null) return null;

    final selectedOrderRaw = state.selectedOrderRaw;
    if (selectedOrderRaw != null &&
        selectedOrderRaw.orderId == selectedOrderId) {
      return selectedOrderRaw;
    }

    for (final order in state.ordersRaw) {
      if (order.orderId == selectedOrderId) return order;
    }

    return null;
  }

  OrderSummary? _findSelectedSummaryOrder(OrdersState state) {
    final selectedOrderId = state.selectedOrderId;
    if (selectedOrderId == null) return null;

    final selectedOrderSummary = state.selectedOrderSummary;
    if (selectedOrderSummary != null &&
        selectedOrderSummary.orderId == selectedOrderId) {
      return selectedOrderSummary;
    }

    for (final order in state.orders) {
      if (order.orderId == selectedOrderId) return order;
    }

    return null;
  }

  void _syncDetailSheet(OrdersState state) {
    if (!mounted) return;

    final selectedOrder = _findSelectedRawOrder(state);
    final selectedSummary = _findSelectedSummaryOrder(state);

    if (selectedOrder == null) {
      _detailDialogOpen = false;
      return;
    }

    if (_detailDialogOpen) return;

    _detailDialogOpen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showOrderDetailSheet(
        context: context,
        order: selectedOrder,
        summary: selectedSummary,
        onClose: () {
          _detailDialogOpen = false;
          if (!mounted) return;
          if (context.read<OrdersCubit>().state.selectedOrderId != null) {
            context.read<OrdersCubit>().selectOrder(null);
          }
        },
        onCallUber: () => context
            .read<OrdersCubit>()
            .callUberDelivery(selectedOrder.orderId)
            .then((result) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.success
                        ? 'Courier solicitado'
                        : (result.message ?? 'No se pudo solicitar el courier'),
                  ),
                ),
              );
            }),
      ).whenComplete(() {
        _detailDialogOpen = false;
        if (!mounted) return;
        if (context.read<OrdersCubit>().state.selectedOrderId != null) {
          context.read<OrdersCubit>().selectOrder(null);
        }
      });
    });
  }
}

class _PrintingProgressBanner extends StatelessWidget {
  const _PrintingProgressBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrintingCubit, PrintingState>(
      buildWhen: (previous, current) =>
          previous.printingProgress != current.printingProgress ||
          previous.printingSecondsRemaining !=
              current.printingSecondsRemaining ||
          previous.printingLabel != current.printingLabel,
      builder: (context, state) {
        final remaining = state.printingSecondsRemaining;
        final label = state.printingProgress == null
            ? 'Enviando recibo a la impresora...'
            : '${state.printingLabel} - hasta ${remaining ?? 0} s';
        return Center(
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: state.printingProgress,
                      backgroundColor: const Color(0xFFE5E7EB),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
