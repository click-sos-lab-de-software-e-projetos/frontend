import 'package:alerta_seguro/data/models/contact.dart';
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
      deps: TestDeps(contacts: const [Contact(id: 'a', name: 'A', relation: 'r', phone: '1', alertEnabled: false)]),
    );

    await holdSos(tester);

    expect(find.text('Ative ao menos um contato em Ajustes.'), findsOneWidget);
    expect(deps.alerts.sent, hasLength(1));
  });

  testWidgets('with active contacts it offers WhatsApp for each', (tester) async {
    final deps = await pumpTestApp(tester, home: const Scaffold(body: SosScreen()));

    await holdSos(tester);
    expect(find.text('Enviar alerta por WhatsApp'), findsOneWidget);

    await tester.tap(find.text('Contato Exemplo 1'));
    expect(deps.launched.single.host, 'wa.me');
    expect(deps.launched.single.path, '/5511900000001');
  });

  testWidgets('releasing early does not fire', (tester) async {
    final deps = await pumpTestApp(tester, home: const Scaffold(body: SosScreen()));
    final gesture = await tester.startGesture(tester.getCenter(find.text('SOS')));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(deps.alerts.sent, isEmpty);
  });
}
