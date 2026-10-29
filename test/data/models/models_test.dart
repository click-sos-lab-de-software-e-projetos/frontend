import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/models/occurrence.dart';
import 'package:alerta_seguro/data/models/occurrence_report.dart';
import 'package:alerta_seguro/data/models/sos_alert.dart';
import 'package:alerta_seguro/data/models/sos_settings.dart';
import 'package:alerta_seguro/data/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Contact', () {
    const contact = Contact(id: '1', name: 'Ana', relation: 'Mãe', phone: '(11) 9', alertEnabled: false);

    test('round-trips through JSON', () {
      expect(Contact.fromJson(contact.toJson()), contact);
    });

    test('fromJson applies defaults', () {
      final c = Contact.fromJson(const {'id': '2', 'name': 'Bia', 'phone': '1'});
      expect(c.relation, 'Contato');
      expect(c.alertEnabled, isTrue);
    });

    test('copyWith changes only given fields', () {
      final c = contact.copyWith(alertEnabled: true);
      expect(c, const Contact(id: '1', name: 'Ana', relation: 'Mãe', phone: '(11) 9'));
    });

    test('initial is safe for empty names', () {
      expect(contact.initial, 'A');
      expect(contact.copyWith(name: '  ').initial, '?');
      expect(contact.copyWith(name: 'ze').initial, 'Z');
    });
  });

  group('Occurrence', () {
    test('parses ints as doubles and defaults severity/type', () {
      final o = Occurrence.fromJson(const {'lat': -23, 'lng': -46.5});
      expect(o, const Occurrence(lat: -23.0, lng: -46.5, severity: 1, type: ''));
    });

    test('round-trips through JSON', () {
      const o = Occurrence(lat: 1.5, lng: 2.5, severity: 3, type: 'Assédio');
      expect(Occurrence.fromJson(o.toJson()), o);
      expect(o.copyWith(severity: 2).severity, 2);
    });
  });

  group('OccurrenceReport', () {
    test('serializes datetime as UTC ISO-8601 and round-trips', () {
      final r = OccurrenceReport(
        address: 'Rua A',
        lat: 1,
        lng: 2,
        type: 'Outro',
        dateTime: DateTime(2026, 10, 21, 22, 30),
      );
      expect(r.toJson()['datetime'], DateTime(2026, 10, 21, 22, 30).toUtc().toIso8601String());
      expect(r.toJson()['datetime'], endsWith('Z'));
      expect(OccurrenceReport.fromJson(r.toJson()), r);
      expect(r.copyWith(address: 'B').address, 'B');
    });
  });

  group('SosAlert', () {
    test('round-trips through JSON, with optional location', () {
      const a = SosAlert(message: 'help', userId: '#1');
      expect(a.toJson(), {'lat': null, 'lng': null, 'message': 'help', 'userId': '#1'});
      expect(SosAlert.fromJson(a.toJson()), a);
    });
  });

  group('UserProfile', () {
    test('round-trips through JSON and tolerates missing fields', () {
      const p = UserProfile(name: 'N', email: 'e@x', phone: '1', protectionId: '#AS');
      expect(UserProfile.fromJson(p.toJson()), p);
      expect(UserProfile.fromJson(const {}), UserProfile.empty);
      expect(p.copyWith(name: 'M').name, 'M');
    });
  });

  group('SosSettings', () {
    test('defaults, JSON round-trip and copyWith', () {
      const s = SosSettings();
      expect(s.message, SosSettings.defaultMessage);
      expect(s.silentAlert, isTrue);
      expect(SosSettings.fromJson(s.toJson()), s);
      expect(s.copyWith(silentAlert: false).silentAlert, isFalse);
    });
  });
}
