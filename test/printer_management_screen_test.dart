import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:mediasis_dashboard_app/presentation/screens/printer_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('printer controls do not overflow on a narrow phone', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    AppLanguage.instance.value = 'es';
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = PrinterStorageService();
    await storage.savePrinter(
      const PrinterConfiguration(
        id: 'printer-1',
        businessLocationId: 'location-1',
        name: 'Impresora principal con un nombre largo',
        host: '192.168.100.155',
        port: 9100,
        lastTestError:
            'La impresora no respondio. Permite conexiones TCP entrantes al puerto 9100 en Windows Defender Firewall.',
      ),
    );
    final cubit = PrintingCubit(
      storage: storage,
      nativeBridge: _FakeNativePrinterBridge(),
    );
    await cubit.loadLocation('location-1');

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const PrinterManagementScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Imprimir prueba'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opciones avanzadas'));
    await tester.pumpAndSettle();
    expect(find.text('Formato de recibo'), findsOneWidget);
    expect(find.text('Texto rapido'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cubit.close();
  });

  testWidgets('rejects 0.0.0.0 as a printer destination', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AppLanguage.instance.value = 'es';
    final cubit = PrintingCubit(nativeBridge: _FakeNativePrinterBridge());
    await cubit.loadLocation('location-1');
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const PrinterManagementScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Agregar IP'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Direccion IP o hostname'),
      '0.0.0.0',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(
      find.textContaining('0.0.0.0 no es una direccion valida'),
      findsOneWidget,
    );
    expect(cubit.state.printers, isEmpty);
    await cubit.close();
  });
}

class _FakeNativePrinterBridge extends NativePrinterBridge {
  @override
  Future<SunmiPrinterInfo> detectSunmiPrinter() async =>
      const SunmiPrinterInfo(available: false);

  @override
  Future<void> synchronize(
    String businessLocationId,
    Iterable<PrinterConfiguration> printers,
  ) async {}

  @override
  Future<List<PrintJob>> takeCompletedJobs() async => const [];
}
