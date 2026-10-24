import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:mediasis_dashboard_app/presentation/screens/printer_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showReceiptActions({
  required BuildContext context,
  required String orderId,
  required String? receiptUrl,
}) async {
  final printingSupported = context.read<PrintingCubit>().isSupported;
  final action = await showModalBottomSheet<_ReceiptAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LocalizedText(
              'Recibo de la orden',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            LocalizedText(
              'Elige como quieres ver o imprimir este recibo.',
              style: TextStyle(
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: printingSupported
                  ? () => Navigator.pop(sheetContext, _ReceiptAction.print)
                  : null,
              icon: const Icon(Icons.print_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: LocalizedText('Imprimir ahora'),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _externalUri(receiptUrl) == null
                  ? null
                  : () => Navigator.pop(sheetContext, _ReceiptAction.browser),
              icon: const Icon(Icons.open_in_browser_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: LocalizedText('Abrir recibo en el navegador'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || action == null) return;
  if (action == _ReceiptAction.browser) {
    final uri = _externalUri(receiptUrl);
    final opened = uri != null && await _launchReceiptUri(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalizedText('No se pudo abrir el recibo.')),
      );
    }
    return;
  }
  await _choosePrinter(context, orderId);
}

Future<void> _choosePrinter(BuildContext context, String orderId) async {
  final cubit = context.read<PrintingCubit>();
  final printers = cubit.state.printers;
  if (printers.isEmpty) {
    final configure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.print_disabled_outlined, size: 38),
        title: const LocalizedText('No hay impresoras'),
        content: const LocalizedText(
          'Configura una impresora IP para imprimir este recibo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const LocalizedText('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const LocalizedText('Configurar impresora'),
          ),
        ],
      ),
    );
    if (configure == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PrinterManagementScreen(),
        ),
      );
    }
    return;
  }
  if (printers.length == 1) {
    await cubit.printOrder(orderId: orderId, printerIds: [printers.first.id]);
    return;
  }
  final selectedIds = await showModalBottomSheet<List<String>>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: LocalizedText(
                'Selecciona una impresora',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.print_rounded)),
              title: const LocalizedText(
                'Imprimir en todas',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: LocalizedText('${printers.length} impresoras'),
              onTap: () => Navigator.pop(
                sheetContext,
                printers.map((printer) => printer.id).toList(),
              ),
            ),
            const Divider(),
            ...printers.map(
              (printer) => ListTile(
                leading: Icon(
                  printer.verified
                      ? Icons.check_circle_rounded
                      : Icons.print_outlined,
                ),
                title: Text(printer.name),
                subtitle: Text('${printer.host}:${printer.port}'),
                onTap: () => Navigator.pop(sheetContext, [printer.id]),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (selectedIds != null && context.mounted) {
    await cubit.printOrder(orderId: orderId, printerIds: selectedIds);
  }
}

Uri? _externalUri(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return null;
  final uri = Uri.tryParse(
    normalized.contains('://') ? normalized : 'https://$normalized',
  );
  return uri != null && (uri.scheme == 'https' || uri.scheme == 'http')
      ? uri
      : null;
}

Future<bool> _launchReceiptUri(Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
  } catch (_) {
    // Some POS devices do not expose a default external browser.
  }
  try {
    return await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {
    return false;
  }
}

enum _ReceiptAction { print, browser }
