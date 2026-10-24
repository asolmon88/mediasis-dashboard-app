import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/presentation/widgets/authenticated_location_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({String? locationName, VoidCallback? onTap}) {
  return MaterialApp(
    home: Scaffold(
      body: AuthenticatedLocationContext(
        locationName: locationName,
        onTap: onTap,
      ),
    ),
  );
}

void main() {
  tearDown(() => AppLanguage.instance.value = 'system');

  testWidgets('shows the selected location clearly in English', (tester) async {
    AppLanguage.instance.value = 'en';
    await tester.pumpWidget(_harness(locationName: 'Pakistan Test'));

    expect(find.text("You're currently in"), findsOneWidget);
    expect(find.text('Pakistan Test'), findsOneWidget);
  });

  testWidgets('shows the selected location clearly in Spanish', (tester) async {
    AppLanguage.instance.value = 'es';
    await tester.pumpWidget(_harness(locationName: 'Pakistan Test'));

    expect(find.text('Actualmente estás en'), findsOneWidget);
    expect(find.text('Pakistan Test'), findsOneWidget);
  });

  testWidgets('uses a safe fallback when no location is selected', (
    tester,
  ) async {
    AppLanguage.instance.value = 'en';
    await tester.pumpWidget(_harness());

    expect(find.text('Select a location'), findsOneWidget);
  });

  testWidgets('opens the location selector when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _harness(locationName: 'Pakistan Test', onTap: () => tapped = true),
    );

    await tester.tap(find.byType(AuthenticatedLocationContext));
    expect(tapped, isTrue);
  });
}
