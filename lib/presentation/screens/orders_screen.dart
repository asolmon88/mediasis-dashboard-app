import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'dart:async';

import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:mediasis_dashboard_app/presentation/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final Timer _timer;
  late final AppLifecycleListener _appLifecycleListener;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _appLifecycleListener = AppLifecycleListener(
      onResume: _refreshOrdersOnResume,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = context.watch<LocationCubit>().state;

    return BlocListener<OrdersCubit, OrdersState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage,
      listener: (context, ordersState) {
        final messenger = ScaffoldMessenger.of(context);

        messenger.hideCurrentSnackBar();

        if (ordersState.errorMessage.isNotEmpty &&
            ordersState.status != OrdersStatus.failure) {
          messenger.showSnackBar(
            SnackBar(content: LocalizedText(ordersState.errorMessage)),
          );
          context.read<OrdersCubit>().clearTransientFeedback();
        }
      },
      child: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, ordersState) {
          if (ordersState.status == OrdersStatus.loading ||
              ordersState.status == OrdersStatus.initial) {
            return const OrdersLoadingView();
          }

          if (ordersState.status == OrdersStatus.failure) {
            return OrdersErrorView(message: ordersState.errorMessage);
          }

          if (ordersState.status == OrdersStatus.empty) {
            return OrdersEmptyView(
              locationName: locationState.selectedLocation?.shortName,
              onRefresh: () => _reloadCurrentLocationOrders(),
              onChangeLocation: () {
                context.read<LocationCubit>().showLocationSelector();
              },
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isPhoneLayout = isCompactWindow(context);

              final boardContent = isPhoneLayout
                  ? OrdersMobileTabs(now: _now, orders: ordersState.orders)
                  : OrdersBoardView(now: _now, orders: ordersState.orders);

              return boardContent;
            },
          );
        },
      ),
    );
  }

  void _refreshOrdersOnResume() {
    _reloadCurrentLocationOrders();
  }

  Future<void> _reloadCurrentLocationOrders() async {
    if (!mounted) return;

    final location = context.read<LocationCubit>().state.selectedLocation;
    if (location == null) return;

    await context.read<PrintingCubit>().refreshNativeJobs();
    if (!mounted) return;
    await context.read<OrdersCubit>().loadOrders(
      location.businessLocationId,
      recoverAutomaticPrinting: true,
    );
  }
}
