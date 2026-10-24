import 'package:mediasis_dashboard_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup errors remain visible to the user', (tester) async {
    await tester.pumpWidget(
      const StartupErrorApp(message: 'Falta configuración de prueba.'),
    );

    expect(find.text('No se pudo iniciar la app'), findsOneWidget);
    expect(find.text('Falta configuración de prueba.'), findsOneWidget);
  });
}
