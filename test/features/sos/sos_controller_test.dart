import 'package:alerta_seguro/core/network/session.dart';
import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/models/sos_alert.dart';
import 'package:alerta_seguro/data/models/user_profile.dart';
import 'package:alerta_seguro/data/repositories/alert_repository.dart';
import 'package:alerta_seguro/data/repositories/contact_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/contacts/contacts_controller.dart';
import 'package:alerta_seguro/features/profile/profile_controller.dart';
import 'package:alerta_seguro/features/sos/sos_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAlerts extends FakeAlertRepository {
  @override
  Future<String> send(SosAlert alert) => Future.error(const RepositoryException('Sem contato com consentimento.'));
}

const _tick = Duration(milliseconds: 1);

void main() {
  const contacts = [
    Contact(id: 'a', name: 'A', phone: '+1'),
    Contact(id: 'b', name: 'B', phone: '+2', alertEnabled: false),
  ];

  Future<SosController> build(
    AlertRepository alerts, {
    LocationService? location,
    bool loggedIn = true,
    int maxPolls = 5,
    String? sosMessage,
  }) async {
    final session = Session();
    if (loggedIn) session.start('t');
    final controller = ContactsController(FakeContactRepository(contacts), session);
    await pumpEventQueue();
    return SosController(
      alerts: alerts,
      location: location ?? FakeLocationService((lat: 1, lng: 2)),
      contacts: controller,
      profile: ProfileController(UserProfile.empty.copyWith(sosMessage: sosMessage)),
      session: session,
      countdownSeconds: 2,
      tick: _tick,
      pollEvery: _tick,
      maxPolls: maxPolls,
    );
  }

  /// Phases published while [action] runs.
  Future<List<SosPhase>> phases(SosController c, Future<void> Function() action) async {
    final seen = <SosPhase>[];
    c.addListener(() {
      if (seen.isEmpty || seen.last != c.state.phase) seen.add(c.state.phase);
    });
    await action();
    return seen;
  }

  test('counts down, sends the alert without a message and follows it until sent', () async {
    final alerts = FakeAlertRepository(
      statuses: const [AlertStatus(AlertDelivery.pending), AlertStatus(AlertDelivery.sent, attempts: 1)],
    );
    final c = await build(alerts);
    final seconds = <int>[];
    c.addListener(() {
      if (c.state.phase == SosPhase.countdown) seconds.add(c.state.secondsLeft);
    });

    final seen = await phases(c, c.start);

    expect(seen, [SosPhase.countdown, SosPhase.sending, SosPhase.pending, SosPhase.sent]);
    expect(seconds, [2, 1]);
    expect(alerts.sent, [const SosAlert(latitude: 1, longitude: 2)]);
    expect(c.state.attempts, 1);
    expect(c.busy, isFalse);
  });

  test('cancel during the countdown never calls the server', () async {
    final alerts = FakeAlertRepository();
    final c = await build(alerts);

    final run = c.start();
    expect(c.state.phase, SosPhase.countdown);
    c.cancel();
    await run;

    expect(c.state.phase, SosPhase.idle);
    expect(alerts.sent, isEmpty);
  });

  test('a failed delivery ends with failed', () async {
    final c = await build(FakeAlertRepository(statuses: const [AlertStatus(AlertDelivery.failed, attempts: 5)]));
    await c.start();
    expect(c.state.phase, SosPhase.failed);
    expect(c.state.attempts, 5);
  });

  test('without a final status in time it stops with stillSending', () async {
    final alerts = FakeAlertRepository(statuses: const [AlertStatus(AlertDelivery.pending)]);
    final c = await build(alerts, maxPolls: 3);
    await c.start();
    expect(c.state.phase, SosPhase.stillSending);
  });

  test('a server refusal shows the backend message', () async {
    final c = await build(_FailingAlerts());
    await c.start();
    expect(c.state.phase, SosPhase.error);
    expect(c.state.error, 'Sem contato com consentimento.');
  });

  test('without location or login it does not call the server', () async {
    final alerts = FakeAlertRepository();

    final noLocation = await build(alerts, location: FakeLocationService());
    await noLocation.start();
    expect(noLocation.state.error, SosController.noLocation);

    final loggedOut = await build(alerts, loggedIn: false);
    await loggedOut.start();
    expect(loggedOut.state.error, SosController.notLoggedIn);

    expect(alerts.sent, isEmpty);
  });

  test('WhatsApp fallback targets active contacts with the map link when known', () async {
    final c = await build(FakeAlertRepository());
    expect(c.targets.map((t) => t.id), ['a']);
    expect(c.whatsAppText(), '${SosController.whatsAppDefault} (localização indisponível)');

    await c.start();
    expect(c.whatsAppText(), '${SosController.whatsAppDefault} https://maps.google.com/?q=1.0,2.0');
  });

  test('WhatsApp fallback uses the message saved in Ajustes', () async {
    final c = await build(FakeAlertRepository(), sosMessage: 'Me liga agora');
    expect(c.whatsAppText(), 'Me liga agora (localização indisponível)');
  });

  test('dismiss returns to idle after a final state', () async {
    final c = await build(FakeAlertRepository());
    await c.start();
    c.dismiss();
    expect(c.state.phase, SosPhase.idle);
  });
}
