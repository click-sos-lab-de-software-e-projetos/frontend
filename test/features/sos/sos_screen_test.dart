import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/models/sos_alert.dart';
import 'package:alerta_seguro/data/models/sos_settings.dart';
import 'package:alerta_seguro/features/sos/sos_controller.dart';
import 'package:alerta_seguro/features/sos/sos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

Future<void> holdSos(WidgetTester tester) async {
  final gesture = await tester.startGesture(tester.getCenter(find.text('SOS')));
  // Pump frame by frame so the hold animation can complete.
  for (var i = 0; i < 32; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with no active contacts it asks to enable one', (tester) async {
    final deps = await pumpTestApp(
      tester,
      home: const Scaffold(body: SosScreen()),
      deps: TestDeps(
        loggedIn: true,
        location: FakeLocationService((lat: 1, lng: 2)),
        contacts: const [Contact(id: 'a', name: 'A', phone: '+5511900000001', alertEnabled: false)],
      ),
    );

    await holdSos(tester);

    expect(find.text('Ative ao menos um contato em Ajustes.'), findsOneWidget);
    expect(deps.alerts.sent, [const SosAlert(latitude: 1, longitude: 2, message: SosSettings.defaultMessage)]);
  });

  testWidgets('with active contacts it offers WhatsApp for each', (tester) async {
    final deps = await pumpTestApp(
      tester,
      home: const Scaffold(body: SosScreen()),
      deps: TestDeps(loggedIn: true, location: FakeLocationService((lat: 1, lng: 2))),
    );

    await holdSos(tester);
    expect(find.text('Enviar alerta por WhatsApp'), findsOneWidget);
    expect(deps.alerts.sent, hasLength(1));

    await tester.tap(find.text('Contato Exemplo 1'));
    expect(deps.launched.single.host, 'wa.me');
    expect(deps.launched.single.path, '/5511900000001');
  });

  testWidgets('logged out it asks to log in and does not call the server', (tester) async {
    final deps = await pumpTestApp(tester, home: const Scaffold(body: SosScreen()));

    await holdSos(tester);

    expect(find.text(SosController.notLoggedIn), findsOneWidget);
    expect(deps.alerts.sent, isEmpty);
  });

  testWidgets('releasing early does not fire', (tester) async {
    final deps = await pumpTestApp(tester, home: const Scaffold(body: SosScreen()), deps: TestDeps(loggedIn: true));
    final gesture = await tester.startGesture(tester.getCenter(find.text('SOS')));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(deps.alerts.sent, isEmpty);
  });
}
