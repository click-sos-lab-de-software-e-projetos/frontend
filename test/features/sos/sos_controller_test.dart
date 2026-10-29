import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/models/sos_alert.dart';
import 'package:alerta_seguro/data/models/user_profile.dart';
import 'package:alerta_seguro/data/repositories/alert_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/contacts/contacts_controller.dart';
import 'package:alerta_seguro/features/profile/profile_controller.dart';
import 'package:alerta_seguro/features/settings/sos_settings_controller.dart';
import 'package:alerta_seguro/features/sos/sos_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAlerts implements AlertRepository {
  @override
  Future<void> send(SosAlert alert) => Future.error(const RepositoryException('offline'));
}

void main() {
  const contacts = [
    Contact(id: 'a', name: 'A', relation: 'r', phone: '1'),
    Contact(id: 'b', name: 'B', relation: 'r', phone: '2', alertEnabled: false),
  ];
  final settings = SosSettingsController()..setMessage('Socorro!');
  final profile = ProfileController(const UserProfile(name: 'N', email: 'e', phone: 'p', protectionId: '#AS-1'));

  SosController build(AlertRepository alerts, LocationService location) => SosController(
        alerts: alerts,
        location: location,
        contacts: ContactsController(initial: contacts),
        settings: settings,
        profile: profile,
      );

  test('sends the alert with location and returns active contacts', () async {
    final alerts = FakeAlertRepository();
    final outcome = await build(alerts, FakeLocationService((lat: 1, lng: 2))).trigger();

    expect(outcome.message, 'Socorro! https://maps.google.com/?q=1.0,2.0');
    expect(outcome.targets.map((c) => c.id), ['a']);
    expect(outcome.alertError, isNull);
    expect(alerts.sent, [SosAlert(lat: 1, lng: 2, message: outcome.message, userId: '#AS-1')]);
  });

  test('works without location', () async {
    final outcome = await build(FakeAlertRepository(), FakeLocationService()).trigger();
    expect(outcome.message, 'Socorro! (localização indisponível)');
  });

  test('reports server failure but still returns targets', () async {
    final outcome = await build(_FailingAlerts(), FakeLocationService()).trigger();
    expect(outcome.alertError, 'offline');
    expect(outcome.targets, hasLength(1));
  });
}
