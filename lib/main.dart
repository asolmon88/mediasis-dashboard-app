import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/config/supabase/supabase_config.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:flutter/material.dart';
import 'package:mediasis_dashboard_app/config/theme/app_theme.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:mediasis_dashboard_app/presentation/screens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppLanguage.instance.load();
    SupabaseConfig.validate();
    await initializeDateFormatting();

    await sb.Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.publishableKey,
    );

    try {
      await OrderSoundService.initialize();
    } catch (_) {
      // Audio session config failure is non-fatal
    }

    runApp(const MyApp());
  } catch (error) {
    final message = '$error'.replaceFirst('Bad state: ', '').trim();
    runApp(
      StartupErrorApp(
        message: message.isEmpty
            ? 'No se pudo iniciar la aplicación.'
            : message,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()..initialize()),
        BlocProvider(create: (_) => LocationCubit()),
        BlocProvider(create: (_) => OrdersCubit()),
        BlocProvider(
          create: (context) => PrintingCubit()
            ..bindIncomingOrders(
              context.read<OrdersCubit>().incomingOrderArrivals,
            ),
        ),
        BlocProvider(create: (_) => OrdersTableCubit()),
        BlocProvider(create: (_) => ProductsCubit()),
        BlocProvider(create: (_) => PushNotificationsCubit()..initialize()),
        BlocProvider(create: (_) => DeliveryPreparationCubit()),
        BlocProvider(create: (_) => StoreAvailabilityCubit()),
        BlocProvider(create: (_) => WindowsUpdateCubit()..initialize()),
      ],
      child: const AppShell(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.instance,
      builder: (context, language, _) => MaterialApp(
        locale: AppLanguage.instance.locale,
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        localeResolutionCallback: (locale, supported) =>
            locale?.languageCode == 'en'
            ? const Locale('en')
            : const Locale('es'),
        title: 'Mediasis Orders',
        theme: materialThemeData,
        home: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            final locationCubit = context.read<LocationCubit>();
            final ordersCubit = context.read<OrdersCubit>();
            final ordersTableCubit = context.read<OrdersTableCubit>();
            final productsCubit = context.read<ProductsCubit>();
            final deliveryPreparationCubit = context
                .read<DeliveryPreparationCubit>();
            final storeAvailabilityCubit = context
                .read<StoreAvailabilityCubit>();
            final pushNotificationsCubit = context
                .read<PushNotificationsCubit>();
            final printingCubit = context.read<PrintingCubit>();

            if (state.status == AuthStatus.authenticated) {
              pushNotificationsCubit.synchronizeAuthenticatedLocation(
                authenticated: true,
                userId: state.userId,
                explicitSignInVersion: state.explicitSignInVersion,
              );
              locationCubit.loadLocations();
            } else if (state.status == AuthStatus.unauthenticated) {
              pushNotificationsCubit.handleUnexpectedSignOut();
              locationCubit.reset();
              ordersCubit.reset();
              ordersTableCubit.reset();
              productsCubit.reset();
              deliveryPreparationCubit.reset();
              storeAvailabilityCubit.reset();
              printingCubit.clearActiveLocation();
            }
          },
          child: BlocListener<LocationCubit, LocationState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.selectedLocation?.businessLocationId !=
                    current.selectedLocation?.businessLocationId,
            listener: (context, state) {
              final ordersCubit = context.read<OrdersCubit>();
              final ordersTableCubit = context.read<OrdersTableCubit>();
              final deliveryPreparationCubit = context
                  .read<DeliveryPreparationCubit>();
              final storeAvailabilityCubit = context
                  .read<StoreAvailabilityCubit>();
              final pushNotificationsCubit = context
                  .read<PushNotificationsCubit>();
              final printingCubit = context.read<PrintingCubit>();

              if (state.status == LocationStatus.ready &&
                  state.selectedLocation != null) {
                pushNotificationsCubit.synchronizeAuthenticatedLocation(
                  authenticated: true,
                  userId: context.read<AuthCubit>().state.userId,
                  businessLocationId:
                      state.selectedLocation!.businessLocationId,
                  explicitSignInVersion: context
                      .read<AuthCubit>()
                      .state
                      .explicitSignInVersion,
                );
                ordersCubit.loadOrders(
                  state.selectedLocation!.businessLocationId,
                );
                printingCubit.loadLocation(
                  state.selectedLocation!.businessLocationId,
                );
                storeAvailabilityCubit.loadForLocation(
                  state.selectedLocation!.businessLocationId,
                  market: state.market,
                );
              } else if (state.status == LocationStatus.initial ||
                  state.status == LocationStatus.requiresSelection) {
                pushNotificationsCubit.synchronizeAuthenticatedLocation(
                  authenticated:
                      context.read<AuthCubit>().state.status ==
                      AuthStatus.authenticated,
                  userId: context.read<AuthCubit>().state.userId,
                  explicitSignInVersion: context
                      .read<AuthCubit>()
                      .state
                      .explicitSignInVersion,
                );
                ordersCubit.reset();
                ordersTableCubit.reset();
                deliveryPreparationCubit.reset();
                storeAvailabilityCubit.reset();
                printingCubit.clearActiveLocation();
              }
            },
            child: BlocListener<OrdersCubit, OrdersState>(
              listenWhen: (previous, current) =>
                  previous.failureReason != current.failureReason &&
                  current.failureReason ==
                      OrdersFailureReason.locationAccessDenied,
              listener: (context, state) async {
                await context
                    .read<LocationCubit>()
                    .recoverFromUnauthorizedLocation();
              },
              child: const AppView(),
            ),
          ),
        ),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WindowsUpdateCubit, WindowsUpdateState>(
      builder: (context, updateState) {
        switch (updateState.status) {
          case WindowsUpdateStatus.initial:
          case WindowsUpdateStatus.checking:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case WindowsUpdateStatus.required:
          case WindowsUpdateStatus.downloading:
            return const WindowsUpdateScreen();
          case WindowsUpdateStatus.ready:
            return BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                switch (authState.status) {
                  case AuthStatus.unauthenticated:
                    return const LoginScreen();
                  case AuthStatus.unknown:
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  case AuthStatus.authenticated:
                    return BlocBuilder<LocationCubit, LocationState>(
                      builder: (context, locationState) {
                        switch (locationState.status) {
                          case LocationStatus.initial:
                          case LocationStatus.loading:
                            return const Scaffold(
                              body: Center(child: CircularProgressIndicator()),
                            );
                          case LocationStatus.requiresSelection:
                          case LocationStatus.empty:
                          case LocationStatus.failure:
                            return const LocationSelectorScreen();
                          case LocationStatus.ready:
                            return const AuthenticatedHomeScreen();
                        }
                      },
                    );
                }
              },
            );
        }
      },
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final guidance =
        message.contains('SUPABASE_URL') ||
            message.contains('SUPABASE_PUBLISHABLE_KEY')
        ? 'Esta compilación parece no incluir la configuración requerida para Supabase. '
              'Vuelve a generar el build con los --dart-define correctos.'
        : 'Revisa la configuración del build o intenta nuevamente con una nueva versión.';

    return MaterialApp(
      title: 'Mediasis Orders',
      theme: materialThemeData,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(2.4.ws(context).clamp(20.0, 24.0)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 92.ws(context).clamp(360.0, 520.0),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    2.8.ws(context).clamp(24.0, 28.0),
                  ),
                  border: Border.all(
                    color: materialThemeData.colorScheme.outlineVariant,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 2.4.ws(context).clamp(20.0, 24.0),
                      offset: Offset(0, 1.4.hs(context).clamp(12.0, 14.0)),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.ws(context).clamp(18.0, 20.0),
                    vertical: 2.4.hs(context).clamp(20.0, 24.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No se pudo iniciar la app',
                        style: materialThemeData.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 1.2.hs(context).clamp(10.0, 12.0)),
                      Text(
                        guidance,
                        style: materialThemeData.textTheme.bodyMedium?.copyWith(
                          color: materialThemeData.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 1.6.hs(context).clamp(14.0, 16.0)),
                      SelectableText(
                        message,
                        style: materialThemeData.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
