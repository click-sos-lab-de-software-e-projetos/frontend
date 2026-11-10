import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/models/sos_alert.dart';
import 'package:alerta_seguro/features/profile/privacy_screen.dart';
import 'package:alerta_seguro/features/sos/sos_controller.dart';
import 'package:alerta_seguro/features/sos/sos_screen.dart';
import 'package:alerta_seguro/features/sos/widgets/sos_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _screen = Scaffold(body: SosScreen());

/// Taps SOS and lets the 5 s countdown run out.
Future<void> tapAndWait(WidgetTester tester) async {
  await tester.tap(find.text('SOS'));
  await tester.pumpAndSettle();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the privacy notice before any tap', (tester) async {
    await pumpTestApp(tester, home: _screen);

    expect(find.text(SosScreen.privacy), findsOneWidget);
  });

  testWidgets('one tap counts down, then sends without a typed message', (tester) async {
    final deps = await pumpTestApp(
      tester,
      home: _screen,
      deps: TestDeps(loggedIn: true, location: FakeLocationService((lat: 1, lng: 2))),
    );

    await tester.tap(find.text('SOS'));
    await tester.pump();
    expect(find.text(SosStatusCard.countdown(5)), findsOneWidget);
    expect(deps.alerts.sent, isEmpty);

    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    expect(deps.alerts.sent, [const SosAlert(latitude: 1, longitude: 2)]);
    expect(find.text(SosStatusCard.sent), findsOneWidget);
  });

  testWidgets('cancelling during the countdown sends nothing', (tester) async {
    final deps = await pumpTestApp(tester, home: _screen, deps: TestDeps(loggedIn: true));

    await tester.tap(find.text('SOS'));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Cancelar'));
    await tester.pump(const Duration(seconds: 10));

    expect(deps.alerts.sent, isEmpty);
    expect(find.text('SOS'), findsOneWidget);
  });

  testWidgets('server failure offers WhatsApp for each active contact', (tester) async {
    final deps = TestDeps(loggedIn: true, location: FakeLocationService((lat: 1, lng: 2)));
    deps.alerts.statuses = const [AlertStatus(AlertDelivery.failed, attempts: 3)];
    await pumpTestApp(tester, home: _screen, deps: deps);

    await tapAndWait(tester);
    expect(find.text(SosStatusCard.failed), findsOneWidget);

    await tester.tap(find.text(SosStatusCard.whatsApp));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contato Exemplo 1'));

    expect(deps.launched.single.host, 'wa.me');
    expect(deps.launched.single.path, '/5511900000001');
    expect(deps.launched.single.queryParameters['text'], contains('maps'));
  });

  testWidgets('with no active contacts the WhatsApp fallback is hidden', (tester) async {
    await pumpTestApp(
      tester,
      home: _screen,
      deps: TestDeps(
        loggedIn: true,
        contacts: const [Contact(id: 'a', name: 'A', phone: '+5511900000001', alertEnabled: false)],
      ),
    );

    await tapAndWait(tester);

    expect(find.text(SosStatusCard.whatsApp), findsNothing);
  });

  testWidgets('logged out it asks to log in and does not call the server', (tester) async {
    final deps = await pumpTestApp(tester, home: _screen);

    await tapAndWait(tester);

    expect(find.text(SosController.notLoggedIn), findsOneWidget);
    expect(deps.alerts.sent, isEmpty);
  });

  testWidgets('explains location before asking, and "Agora não" sends nothing', (tester) async {
    final location = FakeLocationService((lat: 1, lng: 2))..access = LocationAccess.canAsk;
    final deps = await pumpTestApp(tester, home: _screen, deps: TestDeps(loggedIn: true, location: location));

    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();
    expect(find.text(SosScreen.whyLocation), findsOneWidget);

    await tester.tap(find.text('Agora não'));
    await tester.pump(const Duration(seconds: 10));

    expect(location.requests, 0);
    expect(deps.alerts.sent, isEmpty);
  });

  testWidgets('the explanation links to the privacy policy without asking the OS', (tester) async {
    final location = FakeLocationService((lat: 1, lng: 2))..access = LocationAccess.canAsk;
    final deps = await pumpTestApp(tester, home: _screen, deps: TestDeps(loggedIn: true, location: location));

    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver política de privacidade'));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(location.requests, 0);
    expect(deps.alerts.sent, isEmpty);
  });

  testWidgets('after accepting the explanation it asks the OS and sends', (tester) async {
    final location = FakeLocationService((lat: 1, lng: 2))..access = LocationAccess.canAsk;
    final deps = await pumpTestApp(tester, home: _screen, deps: TestDeps(loggedIn: true, location: location));

    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tapAndWait(tester);

    expect(location.requests, 1);
    expect(deps.alerts.sent, hasLength(1));
  });

  testWidgets('denied forever explains and opens the settings, without calling the server', (tester) async {
    final location = FakeLocationService((lat: 1, lng: 2))..access = LocationAccess.deniedForever;
    final deps = await pumpTestApp(tester, home: _screen, deps: TestDeps(loggedIn: true, location: location));

    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();
    expect(find.text(SosScreen.deniedReason(LocationAccess.deniedForever)), findsOneWidget);

    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();

    expect(location.openedSettings, [LocationAccess.deniedForever]);
    expect(deps.alerts.sent, isEmpty);
  });

  testWidgets('location off can still send by WhatsApp, without a link', (tester) async {
    final location = FakeLocationService((lat: 1, lng: 2))..access = LocationAccess.serviceOff;
    final deps = await pumpTestApp(tester, home: _screen, deps: TestDeps(loggedIn: true, location: location));

    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(SosScreen.whatsAppOnly));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contato Exemplo 1'));

    expect(deps.launched.single.queryParameters['text'], isNot(contains('maps')));
    expect(deps.alerts.sent, isEmpty);
  });
}
