import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:mediasis_dashboard_app/presentation/screens/delivery_preparation_screen.dart';
import 'package:mediasis_dashboard_app/presentation/screens/printer_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A compact launchpad for settings. Detailed controls live in focused pages.
class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = 4.ws(context).clamp(16.0, 40.0);
    final location = context.watch<LocationCubit>().state.selectedLocation;
    return BlocListener<StoreAvailabilityCubit, StoreAvailabilityState>(
      listenWhen: (previous, current) =>
          previous.transientMessage != current.transientMessage,
      listener: (context, state) {
        if (state.transientMessage.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: LocalizedText(state.transientMessage)),
        );
        context.read<StoreAvailabilityCubit>().clearTransientMessage();
      },
      child: BlocBuilder<StoreAvailabilityCubit, StoreAvailabilityState>(
        builder: (context, state) => ListView(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 32),
          children: [
            _StoreActionCard(
              isOpen: state.isOpen,
              isLoading: state.status == StoreAvailabilityStatus.loading,
              isSaving: state.isSaving,
              enabled: location != null,
              locationName: location?.shortName,
              errorMessage: state.errorMessage,
              onToggleRequested: () => _confirmStoreToggle(context, state),
            ),
            const SizedBox(height: 24),
            LocalizedText(
              'Configuración',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            LocalizedText(
              'Personaliza esta tablet y administra las herramientas del local.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            _SettingsMenu(
              enabled: location != null,
              locationName: location?.shortName,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStoreToggle(
    BuildContext context,
    StoreAvailabilityState state,
  ) async {
    final shouldClose = state.isOpen;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: LocalizedText(shouldClose ? 'Cerrar app' : 'Abrir app'),
        content: LocalizedText(
          shouldClose
              ? 'Confirmas que quieres cerrar la app y dejar de recibir pedidos nuevos?'
              : 'Confirmas que quieres abrir la app y volver a recibir pedidos nuevos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const LocalizedText('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: LocalizedText(shouldClose ? 'Cerrar' : 'Abrir'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<StoreAvailabilityCubit>().setClosed(shouldClose);
    }
  }
}

class _StoreActionCard extends StatelessWidget {
  const _StoreActionCard({
    required this.isOpen,
    required this.isLoading,
    required this.isSaving,
    required this.enabled,
    required this.locationName,
    required this.errorMessage,
    required this.onToggleRequested,
  });

  final bool isOpen;
  final bool isLoading;
  final bool isSaving;
  final bool enabled;
  final String? locationName;
  final String errorMessage;
  final Future<void> Function() onToggleRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unavailable = !enabled || isLoading || isSaving;
    final title = isOpen ? 'La app está abierta' : 'La app está cerrada';
    final detail = errorMessage.isNotEmpty
        ? errorMessage
        : !enabled
        ? 'Selecciona un local para cambiar este estado.'
        : isOpen
        ? '${locationName ?? context.tr('Este local')} ${context.tr('puede recibir pedidos nuevos.')}'
        : '${locationName ?? context.tr('Este local')} ${context.tr('no recibirá pedidos nuevos.')}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOpen ? Icons.storefront_rounded : Icons.storefront_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOpen
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LocalizedText(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  LocalizedText(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isSaving)
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Semantics(
                label: isOpen ? 'Cerrar pedidos' : 'Abrir pedidos',
                child: Switch.adaptive(
                  value: isOpen,
                  onChanged: unavailable ? null : (_) => onToggleRequested(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu({required this.enabled, required this.locationName});

  final bool enabled;
  final String? locationName;

  @override
  Widget build(BuildContext context) {
    final push = context.watch<PushNotificationsCubit>().state;
    final printing = context.watch<PrintingCubit>().state;
    final printingSupported = context.read<PrintingCubit>().isSupported;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _SettingsMenuTile(
            icon: Icons.language_rounded,
            title: 'Idioma',
            detail: _languageLabel(context),
            onTap: () => _open(context, const LanguageSettingsScreen()),
          ),
          const Divider(height: 1),
          _SettingsMenuTile(
            icon: push.isRegistered
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            title: 'Notificaciones de pedidos',
            detail: _notificationSummary(push),
            onTap: () => _open(context, const NotificationSettingsScreen()),
          ),
          const Divider(height: 1),
          _SettingsMenuTile(
            icon: Icons.print_rounded,
            title: 'Impresoras de recibos',
            detail: !printingSupported
                ? 'Disponible en Android, iOS y Windows.'
                : printing.printers.isEmpty
                ? 'No hay impresoras configuradas.'
                : '${printing.printers.length} ${context.tr('configurada(s),')} ${printing.automaticPrinterCount} ${context.tr('automática(s).')}',
            enabled:
                printingSupported && printing.businessLocationId.isNotEmpty,
            onTap: () => _open(context, const PrinterManagementScreen()),
          ),
          const Divider(height: 1),
          _SettingsMenuTile(
            icon: Icons.schedule_rounded,
            title: 'Tiempo de preparación de delivery',
            detail: enabled
                ? '${context.tr('Configura los tiempos para ')}${locationName ?? context.tr('el local activo')}.'
                : 'Selecciona un local para administrarlo.',
            enabled: enabled,
            onTap: () => _open(context, const DeliveryPreparationScreen()),
          ),
        ],
      ),
    );
  }

  String _languageLabel(BuildContext context) {
    switch (AppLanguage.instance.value) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return context.tr('Sistema');
    }
  }

  String _notificationSummary(PushNotificationsState state) {
    if (state.isRegistered) return 'Activas para los pedidos nuevos.';
    if (!state.permissionGranted && !state.canRequestPermission) {
      return 'Bloqueadas en los ajustes del dispositivo.';
    }
    if (state.permissionGranted) return 'Pendientes de sincronización.';
    return 'Actívalas para no perder pedidos.';
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _SettingsMenuTile extends StatelessWidget {
  const _SettingsMenuTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.enabled = true,
  });
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListTile(
    enabled: enabled,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
    leading: Icon(icon),
    title: LocalizedText(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: LocalizedText(
      detail,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: enabled ? onTap : null,
  );
}

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LocalizedText('Idioma')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [LanguageSettingsCard()],
    ),
  );
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LocalizedText('Notificaciones de pedidos')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [_NotificationSettingsPanel()],
    ),
  );
}

class _NotificationSettingsPanel extends StatelessWidget {
  const _NotificationSettingsPanel();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<PushNotificationsCubit, PushNotificationsState>(
      builder: (context, state) {
        final details = _detailsFor(state);
        final canAct =
            state.status == PushNotificationsStatus.ready &&
            !state.isRegistered;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(details.$2, color: theme.colorScheme.primary, size: 30),
                const SizedBox(height: 16),
                LocalizedText(
                  details.$1,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                LocalizedText(
                  details.$3,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (state.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const LocalizedText(
                    'No se pudo sincronizar. Intenta nuevamente.',
                  ),
                ],
                if (canAct) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => context
                              .read<PushNotificationsCubit>()
                              .enableFromSettings(),
                    icon: state.isBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(details.$4),
                    label: LocalizedText(details.$5),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  (String, IconData, String, IconData, String) _detailsFor(
    PushNotificationsState state,
  ) {
    if (state.status == PushNotificationsStatus.unsupported) {
      return (
        'Notificaciones no disponibles',
        Icons.devices_rounded,
        'Este dispositivo no admite notificaciones.',
        Icons.devices_rounded,
        '',
      );
    }
    if (state.status == PushNotificationsStatus.initializing ||
        state.status == PushNotificationsStatus.initial) {
      return (
        'Comprobando notificaciones',
        Icons.hourglass_top_rounded,
        'Comprobando el estado de las notificaciones...',
        Icons.hourglass_top_rounded,
        '',
      );
    }
    if (state.isRegistered) {
      return (
        'Notificaciones activas',
        Icons.check_circle_rounded,
        'Este dispositivo recibirá alertas para los pedidos nuevos del local activo.',
        Icons.check_circle_rounded,
        '',
      );
    }
    if (!state.permissionGranted && !state.canRequestPermission) {
      return (
        'Notificaciones bloqueadas',
        Icons.settings_rounded,
        'Actívalas desde los ajustes del dispositivo para recibir pedidos en segundo plano.',
        Icons.settings_rounded,
        'Abrir ajustes',
      );
    }
    if (state.permissionGranted) {
      return (
        'Sincronización pendiente',
        Icons.sync_rounded,
        'El permiso está activo. Sincroniza este dispositivo para recibir pedidos.',
        Icons.sync_rounded,
        'Sincronizar',
      );
    }
    return (
      'Activa las notificaciones',
      Icons.notifications_rounded,
      'Recibirás alertas de pedidos nuevos aunque la app esté en segundo plano.',
      Icons.notifications_rounded,
      'Activar',
    );
  }
}
