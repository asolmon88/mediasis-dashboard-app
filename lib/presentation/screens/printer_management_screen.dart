import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class PrinterManagementScreen extends StatelessWidget {
  const PrinterManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const LocalizedText('Impresoras')),
      body: BlocBuilder<PrintingCubit, PrintingState>(
        builder: (context, state) {
          final busy =
              state.status == PrintingStatus.discovering ||
              state.status == PrintingStatus.printing;
          return ListView(
            padding: EdgeInsets.all(2.4.ws(context).clamp(18.0, 28.0)),
            children: [
              _IntroCard(
                busy: busy,
                onDiscover: () => context.read<PrintingCubit>().discover(),
                onScan: () =>
                    context.read<PrintingCubit>().discover(scanSubnet: true),
                onScanSunmi: defaultTargetPlatform == TargetPlatform.android
                    ? () => context.read<PrintingCubit>().discoverSunmi()
                    : null,
                onManual: () => _showPrinterEditor(context),
              ),
              if (state.status == PrintingStatus.discovering) ...[
                const SizedBox(height: 20),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const LocalizedText('Buscando impresoras disponibles...'),
              ],
              if (state.status == PrintingStatus.printing) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: state.printingProgress,
                  backgroundColor: const Color(0xFFE5E7EB),
                ),
                const SizedBox(height: 8),
                Text(_printingStatus(state)),
              ],
              if (state.discoveredPrinters.isNotEmpty) ...[
                const SizedBox(height: 28),
                const _SectionTitle(
                  title: 'Encontradas',
                  subtitle:
                      'Agrega una impresora para configurarla y probarla.',
                ),
                const SizedBox(height: 12),
                ...state.discoveredPrinters.map(
                  (printer) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.print_rounded),
                      title: Text(printer.name),
                      subtitle: Text(
                        '${printer.host}:${printer.port} - ${printer.source}',
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () => context
                            .read<PrintingCubit>()
                            .addDiscoveredPrinter(printer),
                        child: const LocalizedText('Agregar'),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _SectionTitle(
                title: 'Configuradas',
                subtitle: state.printers.isEmpty
                    ? 'Todavia no hay impresoras para este local.'
                    : '${state.printers.length} impresora(s) guardadas en este dispositivo.',
              ),
              const SizedBox(height: 12),
              if (state.printers.isEmpty)
                const _EmptyPrinters()
              else
                ...state.printers.map(
                  (printer) => _PrinterCard(
                    printer: printer,
                    busy: busy,
                    onEdit: () => _showPrinterEditor(context, printer: printer),
                    onTest: () =>
                        context.read<PrintingCubit>().testPrinter(printer.id),
                    onAutomaticChanged: (value) => context
                        .read<PrintingCubit>()
                        .setAutomaticPrinting(printer.id, value),
                    onReceiptFormatChanged: (value) => context
                        .read<PrintingCubit>()
                        .setReceiptFormat(printer.id, value),
                    onDelete: () => _confirmDelete(context, printer),
                  ),
                ),
              if (state.failedJobs.isNotEmpty) ...[
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'Impresiones fallidas',
                  subtitle:
                      '${state.failedJobs.length} trabajo(s) requieren atencion.',
                ),
                const SizedBox(height: 12),
                ...state.failedJobs.map(
                  (job) => Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.error_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: LocalizedText(
                        'Orden #${job.humanOrderNumber?.isNotEmpty == true ? job.humanOrderNumber : job.orderId}',
                      ),
                      subtitle: LocalizedText(
                        '${job.printerName}\n${job.error ?? 'Error de impresion'}',
                      ),
                      isThreeLine: true,
                      trailing: FilledButton.tonalIcon(
                        onPressed: busy
                            ? null
                            : () => context.read<PrintingCubit>().retryJob(
                                job.id,
                              ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const LocalizedText('Reintentar'),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _printingStatus(PrintingState state) {
    if (state.printingProgress == null) {
      return 'Enviando recibo a la impresora...';
    }
    final remaining = state.printingSecondsRemaining ?? 0;
    return '${state.printingLabel} - hasta $remaining s';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PrinterConfiguration printer,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const LocalizedText('Eliminar impresora'),
        content: LocalizedText(
          'Se eliminara ${printer.name} solo de este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const LocalizedText('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const LocalizedText('Eliminar'),
          ),
        ],
      ),
    );
    if (accepted == true && context.mounted) {
      await context.read<PrintingCubit>().deletePrinter(printer.id);
    }
  }

  Future<void> _showPrinterEditor(
    BuildContext context, {
    PrinterConfiguration? printer,
  }) async {
    final result = await showDialog<_PrinterFormValue>(
      context: context,
      builder: (_) => _PrinterEditorDialog(printer: printer),
    );
    if (result == null || !context.mounted) return;
    await context.read<PrintingCubit>().savePrinter(
      id: printer?.id,
      name: result.name,
      host: result.host,
      port: result.port,
      paperWidth: result.paperWidth,
      supportsCutter: result.supportsCutter,
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.busy,
    required this.onDiscover,
    required this.onScan,
    required this.onScanSunmi,
    required this.onManual,
  });
  final bool busy;
  final VoidCallback onDiscover;
  final VoidCallback onScan;
  final VoidCallback? onScanSunmi;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.print_rounded, size: 38, color: colors.primary),
          const SizedBox(height: 12),
          LocalizedText(
            'Recibos directos a tu red',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: LocalizedText(
              'Conecta impresoras ESC/POS por IP. La configuracion se guarda por local en este dispositivo.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : onDiscover,
                icon: const Icon(Icons.radar_rounded),
                label: const LocalizedText('Buscar'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onScan,
                icon: const Icon(Icons.wifi_find_rounded),
                label: const LocalizedText('Escanear red'),
              ),
              if (onScanSunmi != null)
                OutlinedButton.icon(
                  onPressed: busy ? null : onScanSunmi,
                  icon: const Icon(Icons.point_of_sale_rounded),
                  label: const LocalizedText('Buscar SUNMI'),
                ),
              OutlinedButton.icon(
                onPressed: busy ? null : onManual,
                icon: const Icon(Icons.add_rounded),
                label: const LocalizedText('Agregar IP'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrinterCard extends StatelessWidget {
  const _PrinterCard({
    required this.printer,
    required this.busy,
    required this.onEdit,
    required this.onTest,
    required this.onAutomaticChanged,
    required this.onReceiptFormatChanged,
    required this.onDelete,
  });
  final PrinterConfiguration printer;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onTest;
  final ValueChanged<bool> onAutomaticChanged;
  final ValueChanged<PrinterReceiptFormat> onReceiptFormatChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: printer.verified
                      ? Colors.green.withValues(alpha: 0.12)
                      : colors.surfaceContainerHighest,
                  child: Icon(
                    printer.verified
                        ? Icons.check_rounded
                        : Icons.print_rounded,
                    color: printer.verified
                        ? Colors.green.shade700
                        : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        printer.connectionType ==
                                PrinterConnectionType.sunmiBuiltIn
                            ? 'Integrada${printer.deviceModel?.isNotEmpty == true ? ' | ${printer.deviceModel}' : ''} | ${printer.paperWidth == PrinterPaperWidth.mm58 ? '58 mm' : '80 mm'}'
                            : '${printer.host}:${printer.port}  |  ${printer.paperWidth == PrinterPaperWidth.mm58 ? '58 mm' : '80 mm'}',
                      ),
                      if (printer.lastTestError?.isNotEmpty == true)
                        Text(
                          printer.lastTestError!,
                          style: TextStyle(color: colors.error, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (printer.connectionType == PrinterConnectionType.network)
                  PopupMenuButton<String>(
                    enabled: !busy,
                    tooltip: context.tr('Opciones de impresora'),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: LocalizedText('Editar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline_rounded),
                          title: LocalizedText('Eliminar'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 430;
                final testButton = OutlinedButton.icon(
                  onPressed: busy ? null : onTest,
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const LocalizedText('Imprimir prueba'),
                );
                final automaticControl = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Flexible(
                      child: LocalizedText(
                        'Impresion automatica',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Switch(
                      value: printer.automaticPrinting,
                      onChanged: busy ? null : onAutomaticChanged,
                    ),
                  ],
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      testButton,
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: automaticControl,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [testButton, const Spacer(), automaticControl],
                );
              },
            ),
            const SizedBox(height: 4),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 6),
              title: const LocalizedText(
                'Opciones avanzadas',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              children: [
                DropdownButtonFormField<PrinterReceiptFormat>(
                  initialValue: printer.receiptFormat,
                  decoration: InputDecoration(
                    labelText: context.tr('Formato de recibo'),
                    helperText: context.tr(
                      'El diseno visual reproduce el recibo del sitio web.',
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: PrinterReceiptFormat.visualRaster,
                      child: LocalizedText('Diseno visual'),
                    ),
                    DropdownMenuItem(
                      value: PrinterReceiptFormat.escPosText,
                      child: LocalizedText('Texto rapido'),
                    ),
                  ],
                  onChanged: busy
                      ? null
                      : (value) {
                          if (value != null) onReceiptFormatChanged(value);
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LocalizedText(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      LocalizedText(
        subtitle,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

class _EmptyPrinters extends StatelessWidget {
  const _EmptyPrinters();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Column(
      children: [
        Icon(Icons.print_disabled_outlined, size: 42),
        SizedBox(height: 10),
        LocalizedText(
          'Busca una impresora o agrega su direccion IP.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _PrinterFormValue {
  const _PrinterFormValue({
    required this.name,
    required this.host,
    required this.port,
    required this.paperWidth,
    required this.supportsCutter,
  });
  final String name;
  final String host;
  final int port;
  final PrinterPaperWidth paperWidth;
  final bool supportsCutter;
}

class _PrinterEditorDialog extends StatefulWidget {
  const _PrinterEditorDialog({this.printer});
  final PrinterConfiguration? printer;
  @override
  State<_PrinterEditorDialog> createState() => _PrinterEditorDialogState();
}

class _PrinterEditorDialogState extends State<_PrinterEditorDialog> {
  var _didInitializeControllers = false;
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late PrinterPaperWidth _paperWidth;
  late bool _cutter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeControllers) return;
    _didInitializeControllers = true;
    _name = TextEditingController(
      text: widget.printer?.name ?? context.tr('Impresora principal'),
    );
    _host = TextEditingController(text: widget.printer?.host ?? '');
    _port = TextEditingController(text: '${widget.printer?.port ?? 9100}');
    _paperWidth = widget.printer?.paperWidth ?? PrinterPaperWidth.mm80;
    _cutter = widget.printer?.supportsCutter ?? true;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      context.tr(
        widget.printer == null ? 'Agregar impresora' : 'Editar impresora',
      ),
    ),
    content: SizedBox(
      width: 430,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: context.tr('Nombre')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _host,
              decoration: InputDecoration(
                labelText: context.tr('Direccion IP o hostname'),
                hintText: '192.168.1.80',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _port,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.tr('Puerto'),
                hintText: '9100',
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<PrinterPaperWidth>(
              segments: const [
                ButtonSegment(
                  value: PrinterPaperWidth.mm58,
                  label: Text('58 mm'),
                ),
                ButtonSegment(
                  value: PrinterPaperWidth.mm80,
                  label: Text('80 mm'),
                ),
              ],
              selected: {_paperWidth},
              onSelectionChanged: (value) =>
                  setState(() => _paperWidth = value.first),
            ),
            if (_paperWidth == PrinterPaperWidth.mm80) ...[
              const SizedBox(height: 8),
              LocalizedText(
                'Usa el area imprimible estandar de 512 puntos para evitar cortes laterales.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const LocalizedText('Cortar papel al terminar'),
              value: _cutter,
              onChanged: (value) => setState(() => _cutter = value),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const LocalizedText('Cancelar'),
      ),
      FilledButton(onPressed: _submit, child: const LocalizedText('Guardar')),
    ],
  );

  void _submit() {
    final port = int.tryParse(_port.text.trim());
    final host = _host.text.trim().toLowerCase();
    if (host == '0.0.0.0' || host == '::' || host == '[::]' || host == '::0') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText(
            '0.0.0.0 no es una direccion valida para conectarse. Usa la direccion IPv4 de la impresora, por ejemplo 192.168.x.x.',
          ),
        ),
      );
      return;
    }
    if (_name.text.trim().isEmpty ||
        host.isEmpty ||
        port == null ||
        port < 1 ||
        port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText('Revisa el nombre, la direccion y el puerto.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _PrinterFormValue(
        name: _name.text.trim(),
        host: host,
        port: port,
        paperWidth: _paperWidth,
        supportsCutter: _cutter,
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    super.dispose();
  }
}
