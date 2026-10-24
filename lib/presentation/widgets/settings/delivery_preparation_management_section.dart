import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:flutter/material.dart';

const List<int> deliveryPreparationPresets = [
  5,
  10,
  15,
  20,
  30,
  45,
  60,
  90,
  120,
];

class DeliveryPreparationManagementSection extends StatelessWidget {
  const DeliveryPreparationManagementSection({
    required this.isPhoneLayout,
    required this.rows,
    required this.prepMinutesByRow,
    required this.editingMinutesByRow,
    required this.pendingRows,
    required this.editingRowId,
    required this.enabled,
    required this.locationName,
    required this.onRefresh,
    required this.onEditRequested,
    required this.onPresetSelected,
    required this.onMinutesChanged,
    required this.onSaveRequested,
    required this.onCancelRequested,
    super.key,
  });

  final bool isPhoneLayout;
  final List<DeliveryMethodTableRow> rows;
  final Map<String, int> prepMinutesByRow;
  final Map<String, int> editingMinutesByRow;
  final Map<String, bool> pendingRows;
  final String? editingRowId;
  final bool enabled;
  final String? locationName;
  final VoidCallback onRefresh;
  final ValueChanged<String> onEditRequested;
  final void Function(String rowId, int minutes) onPresetSelected;
  final void Function(String rowId, String rawValue) onMinutesChanged;
  final Future<void> Function(String rowId) onSaveRequested;
  final ValueChanged<String> onCancelRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    'Métodos de entrega',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 0.5.hs(context).clamp(4.0, 6.0)),
                  Text(
                    enabled
                        ? '${context.tr('Configura el tiempo estimado por método para ')}${locationName ?? context.tr('la ubicación activa')}.'
                        : context.tr(
                            'Selecciona una ubicación activa para editar los tiempos de preparación.',
                          ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 0.8.ws(context).clamp(8.0, 12.0)),
            FilledButton.tonalIcon(
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh_rounded,
                size: 1.8.hs(context).clamp(16.0, 18.0),
              ),
              label: const LocalizedText('Refrescar'),
            ),
          ],
        ),
        if (!enabled) ...[
          SizedBox(height: 1.4.hs(context).clamp(12.0, 16.0)),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(
                1.8.ws(context).clamp(16.0, 18.0),
              ),
              border: Border.all(color: const Color(0xFFF3D089)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 1.4.ws(context).clamp(12.0, 14.0),
                vertical: 1.2.hs(context).clamp(10.0, 12.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 1.8.hs(context).clamp(16.0, 18.0),
                  ),
                  SizedBox(width: 1.ws(context).clamp(8.0, 10.0)),
                  Expanded(
                    child: LocalizedText(
                      'Selecciona una ubicación activa para editar tiempo de preparación por local.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7A4C00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        SizedBox(height: 1.8.hs(context).clamp(16.0, 22.0)),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              2.6.ws(context).clamp(24.0, 30.0),
            ),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.78),
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
            padding: EdgeInsets.symmetric(
              horizontal: 1.2.ws(context).clamp(12.0, 16.0),
              vertical: 0.6.hs(context).clamp(6.0, 10.0),
            ),
            child: Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  _DeliveryMethodRowCard(
                    row: rows[index],
                    isPhoneLayout: isPhoneLayout,
                    prepMinutes: prepMinutesByRow[rows[index].uid] ?? 5,
                    editingMinutes:
                        editingMinutesByRow[rows[index].uid] ??
                        prepMinutesByRow[rows[index].uid] ??
                        5,
                    isEditing: editingRowId == rows[index].uid,
                    isPending: pendingRows[rows[index].uid] == true,
                    enabled: enabled,
                    onEditRequested: () => onEditRequested(rows[index].uid),
                    onPresetSelected: (minutes) =>
                        onPresetSelected(rows[index].uid, minutes),
                    onMinutesChanged: (rawValue) =>
                        onMinutesChanged(rows[index].uid, rawValue),
                    onSaveRequested: () => onSaveRequested(rows[index].uid),
                    onCancelRequested: () => onCancelRequested(rows[index].uid),
                  ),
                  if (index != rows.length - 1)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 1.hs(context).clamp(8.0, 10.0),
                      ),
                      child: Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.52,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliveryMethodRowCard extends StatelessWidget {
  const _DeliveryMethodRowCard({
    required this.row,
    required this.isPhoneLayout,
    required this.prepMinutes,
    required this.editingMinutes,
    required this.isEditing,
    required this.isPending,
    required this.enabled,
    required this.onEditRequested,
    required this.onPresetSelected,
    required this.onMinutesChanged,
    required this.onSaveRequested,
    required this.onCancelRequested,
  });

  final DeliveryMethodTableRow row;
  final bool isPhoneLayout;
  final int prepMinutes;
  final int editingMinutes;
  final bool isEditing;
  final bool isPending;
  final bool enabled;
  final VoidCallback onEditRequested;
  final ValueChanged<int> onPresetSelected;
  final ValueChanged<String> onMinutesChanged;
  final Future<void> Function() onSaveRequested;
  final VoidCallback onCancelRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      _methodIcon(row.name),
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 1.2.ws(context).clamp(10.0, 14.0)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (row.instructions.trim().isNotEmpty) ...[
                          SizedBox(height: 0.4.hs(context).clamp(4.0, 6.0)),
                          Text(
                            row.instructions,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        SizedBox(height: 0.8.hs(context).clamp(8.0, 10.0)),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 0.8.ws(context).clamp(8.0, 10.0),
                          runSpacing: 0.8.hs(context).clamp(8.0, 10.0),
                          children: [
                            Text(
                              formatDeliveryMinutesHuman(prepMinutes),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            _DeliveryBadge(
                              label: context.tr(
                                row.visibility ? 'ACTIVO' : 'INACTIVO',
                              ),
                              backgroundColor: row.visibility
                                  ? const Color(0xFFE8F7EA)
                                  : theme.colorScheme.surfaceContainerHighest,
                              textColor: row.visibility
                                  ? const Color(0xFF2C8E45)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 1.ws(context).clamp(8.0, 12.0)),
            OutlinedButton.icon(
              onPressed: enabled && !isPending ? onEditRequested : null,
              icon: Icon(
                Icons.edit_outlined,
                size: 1.8.hs(context).clamp(16.0, 18.0),
              ),
              label: const LocalizedText('Editar'),
            ),
          ],
        ),
        if (isEditing) ...[
          SizedBox(height: 1.6.hs(context).clamp(14.0, 18.0)),
          Container(
            padding: EdgeInsets.all(1.2.ws(context).clamp(12.0, 14.0)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                2.ws(context).clamp(18.0, 20.0),
              ),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
              ),
              color: theme.colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  'Tiempo hasta que el pedido esté listo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 1.2.hs(context).clamp(10.0, 12.0)),
                Wrap(
                  spacing: 0.8.ws(context).clamp(8.0, 10.0),
                  runSpacing: 0.8.hs(context).clamp(8.0, 10.0),
                  children: [
                    for (final preset in deliveryPreparationPresets)
                      ChoiceChip(
                        label: Text(formatDeliveryMinutesHuman(preset)),
                        selected: editingMinutes == preset,
                        onSelected: isPending
                            ? null
                            : (_) => onPresetSelected(preset),
                      ),
                  ],
                ),
                SizedBox(height: 1.2.hs(context).clamp(10.0, 12.0)),
                SizedBox(
                  width: 16.ws(context).clamp(120.0, 160.0),
                  child: TextFormField(
                    key: ValueKey('${row.uid}-$editingMinutes'),
                    initialValue: '$editingMinutes',
                    keyboardType: TextInputType.number,
                    enabled: !isPending,
                    onChanged: onMinutesChanged,
                    decoration: InputDecoration(
                      labelText: context.tr('Minutos'),
                    ),
                  ),
                ),
                SizedBox(height: 1.2.hs(context).clamp(10.0, 12.0)),
                Row(
                  children: [
                    FilledButton(
                      onPressed: isPending ? null : () => onSaveRequested(),
                      child: isPending
                          ? SizedBox(
                              width: 1.8.hs(context).clamp(16.0, 18.0),
                              height: 1.8.hs(context).clamp(16.0, 18.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 0.2.hs(context).clamp(2.0, 3.0),
                              ),
                            )
                          : const LocalizedText('Guardar'),
                    ),
                    SizedBox(width: 1.ws(context).clamp(8.0, 10.0)),
                    OutlinedButton(
                      onPressed: isPending ? null : onCancelRequested,
                      child: const LocalizedText('Cancelar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

IconData _methodIcon(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('pickup') || normalized.contains('pick')) {
    return Icons.shopping_bag_outlined;
  }
  if (normalized.contains('mesa') || normalized.contains('table')) {
    return Icons.local_pharmacy_outlined;
  }
  return Icons.delivery_dining_outlined;
}

class _DeliveryBadge extends StatelessWidget {
  const _DeliveryBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(2.2.hs(context).clamp(16.0, 999.0)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 1.2.ws(context).clamp(10.0, 12.0),
          vertical: 0.7.hs(context).clamp(6.0, 7.0),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
