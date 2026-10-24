import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:flutter/material.dart';

class SettingsManagementSection extends StatelessWidget {
  const SettingsManagementSection({
    required this.isPhoneLayout,
    required this.isOpen,
    required this.isLoading,
    required this.isSaving,
    required this.enabled,
    required this.locationName,
    required this.note,
    required this.errorMessage,
    required this.onToggleRequested,
    required this.onOpenDeliveryPreparation,
    super.key,
  });

  final bool isPhoneLayout;
  final bool isOpen;
  final bool isLoading;
  final bool isSaving;
  final bool enabled;
  final String? locationName;
  final String note;
  final String errorMessage;
  final Future<void> Function() onToggleRequested;
  final Future<void> Function() onOpenDeliveryPreparation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 92.ws(context).clamp(640.0, 780.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText(
            'Configuración',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 0.6.hs(context).clamp(6.0, 10.0)),
          LocalizedText(
            'Maneja la app',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.4.hs(context).clamp(20.0, 28.0)),
          _SettingsHintCard(
            isOpen: isOpen,
            locationName: locationName,
            note: note,
            errorMessage: errorMessage,
          ),
          SizedBox(height: 1.6.hs(context).clamp(14.0, 20.0)),
          _SettingsGroup(
            child: _StoreAvailabilityTile(
              isPhoneLayout: isPhoneLayout,
              isOpen: isOpen,
              isLoading: isLoading,
              isSaving: isSaving,
              enabled: enabled,
              locationName: locationName,
              onPressed: enabled && !isLoading && !isSaving
                  ? onToggleRequested
                  : null,
            ),
          ),
          SizedBox(height: 1.6.hs(context).clamp(14.0, 20.0)),
          _SettingsGroup(
            child: _SettingsNavigationTile(
              isPhoneLayout: isPhoneLayout,
              enabled: enabled,
              locationName: locationName,
              onPressed: onOpenDeliveryPreparation,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2.6.ws(context).clamp(24.0, 30.0)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 2.6.ws(context).clamp(24.0, 30.0),
            offset: Offset(0, 1.8.hs(context).clamp(14.0, 18.0)),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsNavigationTile extends StatelessWidget {
  const _SettingsNavigationTile({
    required this.isPhoneLayout,
    required this.enabled,
    required this.locationName,
    required this.onPressed,
  });

  final bool isPhoneLayout;
  final bool enabled;
  final String? locationName;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final textBlock = _TileTextBlock(
      title: 'Tiempo de preparación de delivery',
      subtitle: enabled
          ? 'Configura el tiempo de preparación por método para ${locationName ?? 'la ubicación activa'}.'
          : 'Selecciona un local para administrar los tiempos de preparación.',
    );
    final action = FilledButton.tonalIcon(
      onPressed: () => onPressed(),
      icon: Icon(
        Icons.arrow_forward_rounded,
        size: 1.8.hs(context).clamp(16.0, 18.0),
      ),
      label: const LocalizedText('Gestionar'),
    );

    return _SettingsTileFrame(
      isPhoneLayout: isPhoneLayout,
      leadingIcon: Icons.schedule_rounded,
      content: textBlock,
      action: action,
    );
  }
}

class _StoreAvailabilityTile extends StatelessWidget {
  const _StoreAvailabilityTile({
    required this.isPhoneLayout,
    required this.isOpen,
    required this.isLoading,
    required this.isSaving,
    required this.enabled,
    required this.locationName,
    required this.onPressed,
  });

  final bool isPhoneLayout;
  final bool isOpen;
  final bool isLoading;
  final bool isSaving;
  final bool enabled;
  final String? locationName;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final title = isOpen ? 'Cerrar app' : 'Abrir app';
    final subtitle = !enabled
        ? 'Necesitas elegir un local para cambiar este estado.'
        : isLoading
        ? 'Estamos consultando el estado actual de la app.'
        : isOpen
        ? 'La app no recibira pedidos nuevos hasta que la vuelvas a abrir.'
        : 'La app seguira disponible para recibir pedidos nuevos.';
    final textBlock = _TileTextBlock(
      title: title,
      subtitle: subtitle,
      footer: (locationName ?? '').isNotEmpty
          ? _StatusBadge(label: locationName!, active: enabled)
          : null,
    );
    final action = FilledButton(
      onPressed: onPressed == null ? null : () => onPressed!.call(),
      child: isSaving
          ? SizedBox(
              width: 1.8.hs(context).clamp(16.0, 18.0),
              height: 1.8.hs(context).clamp(16.0, 18.0),
              child: CircularProgressIndicator(
                strokeWidth: 0.2.hs(context).clamp(2.0, 3.0),
              ),
            )
          : Text(context.tr(isOpen ? 'Cerrar' : 'Abrir')),
    );

    return _SettingsTileFrame(
      isPhoneLayout: isPhoneLayout,
      leadingIcon: isOpen
          ? Icons.store_mall_directory_outlined
          : Icons.storefront_outlined,
      content: textBlock,
      action: action,
    );
  }
}

class _SettingsTileFrame extends StatelessWidget {
  const _SettingsTileFrame({
    required this.isPhoneLayout,
    required this.leadingIcon,
    required this.content,
    required this.action,
  });

  final bool isPhoneLayout;
  final IconData leadingIcon;
  final Widget content;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final spacing = 1.4.ws(context).clamp(12.0, 18.0);
    final actionSpacing = 1.6.hs(context).clamp(14.0, 18.0);

    if (isPhoneLayout) {
      return Padding(
        padding: EdgeInsets.all(2.2.ws(context).clamp(18.0, 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TileLeadingIcon(icon: leadingIcon, isPhoneLayout: true),
                SizedBox(width: spacing),
                Expanded(child: content),
              ],
            ),
            SizedBox(height: actionSpacing),
            SizedBox(width: double.infinity, child: action),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(2.2.ws(context).clamp(18.0, 24.0)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TileLeadingIcon(icon: leadingIcon, isPhoneLayout: false),
          SizedBox(width: spacing),
          Expanded(child: content),
          SizedBox(width: 1.2.ws(context).clamp(10.0, 12.0)),
          action,
        ],
      ),
    );
  }
}

class _TileLeadingIcon extends StatelessWidget {
  const _TileLeadingIcon({required this.icon, required this.isPhoneLayout});

  final IconData icon;
  final bool isPhoneLayout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = isPhoneLayout
        ? 4.8.hs(context).clamp(44.0, 48.0)
        : 5.6.hs(context).clamp(50.0, 56.0);
    final iconInnerSize = isPhoneLayout
        ? 2.2.hs(context).clamp(20.0, 22.0)
        : 2.4.hs(context).clamp(22.0, 24.0);

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(1.8.ws(context).clamp(16.0, 18.0)),
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: iconInnerSize),
    );
  }
}

class _TileTextBlock extends StatelessWidget {
  const _TileTextBlock({
    required this.title,
    required this.subtitle,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 0.4.hs(context).clamp(4.0, 6.0)),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (footer != null) ...[
          SizedBox(height: 0.8.hs(context).clamp(8.0, 10.0)),
          footer!,
        ],
      ],
    );
  }
}

class _SettingsHintCard extends StatelessWidget {
  const _SettingsHintCard({
    required this.isOpen,
    required this.locationName,
    required this.note,
    required this.errorMessage,
  });

  final bool isOpen;
  final String? locationName;
  final String note;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = errorMessage.isNotEmpty
        ? 'No se pudo consultar la app'
        : isOpen
        ? 'App operando normal'
        : 'App cerrada';
    final body = errorMessage.isNotEmpty
        ? errorMessage
        : note.trim().isNotEmpty
        ? note
        : locationName == null
        ? 'Este estado se consulta directamente desde la configuración activa del local.'
        : isOpen
        ? '$locationName está disponible para recibir pedidos en este momento.'
        : '$locationName no está disponible para recibir pedidos en este momento.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(2.4.ws(context).clamp(20.0, 24.0)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(2.ws(context).clamp(16.0, 20.0)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4.hs(context).clamp(36.0, 40.0),
              height: 4.hs(context).clamp(36.0, 40.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(
                  1.4.ws(context).clamp(12.0, 14.0),
                ),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.primary,
                size: 1.8.hs(context).clamp(16.0, 18.0),
              ),
            ),
            SizedBox(width: 1.2.ws(context).clamp(10.0, 14.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.hs(context).clamp(4.0, 6.0)),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2.2.hs(context).clamp(16.0, 999.0)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 1.2.ws(context).clamp(10.0, 12.0),
          vertical: 0.7.hs(context).clamp(6.0, 7.0),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: active
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
