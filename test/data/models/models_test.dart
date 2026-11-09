import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/models/occurrence.dart';
import 'package:alerta_seguro/data/models/occurrence_report.dart';
import 'package:alerta_seguro/data/models/sos_alert.dart';
import 'package:alerta_seguro/data/models/sos_settings.dart';
import 'package:alerta_seguro/data/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Contact', () {
    test('parses the API response', () {
      final c = Contact.fromJson(const {
        'id': '1',
        'nome': 'Ana',
        'telefone_whatsapp': '+5511900000001',
        'ativo': false,
        'consentido_em': '2026-05-01T12:00:00Z',
        'criado_em': '2026-05-01T11:00:00Z',
      });
      expect(
        c,
        Contact(
          id: '1',
          name: 'Ana',
          phone: '+5511900000001',
          alertEnabled: false,
          consentedAt: DateTime.utc(2026, 5, 1, 12),
        ),
      );
      expect(c.hasConsent, isTrue);
    });

    test('consent is pending when consentido_em is null', () {
      final c = Contact.fromJson(const {'id': '2', 'nome': 'Bia', 'telefone_whatsapp': '+1', 'ativo': true});
      expect(c.hasConsent, isFalse);
      expect(c.alertEnabled, isTrue);
    });

    test('copyWith keeps consent and changes only given fields', () {
      final c = Contact(id: '1', name: 'Ana', phone: '+1', alertEnabled: false, consentedAt: DateTime.utc(2026));
      expect(
        c.copyWith(alertEnabled: true),
        Contact(id: '1', name: 'Ana', phone: '+1', consentedAt: DateTime.utc(2026)),
      );
    });

    test('consent status is confirmed, refused or pending', () {
      final refused = Contact.fromJson(const {
        'id': '3',
        'nome': 'Caio',
        'telefone_whatsapp': '+1',
        'consentido_em': null,
        'recusado_em': '2026-05-02T12:00:00Z',
      });
      expect(refused.refusedAt, DateTime.utc(2026, 5, 2, 12));
      expect(refused.consentStatus, ConsentStatus.refused);
      final confirmed = Contact(id: '1', name: 'A', phone: '+1', consentedAt: DateTime.utc(2026));
      expect(confirmed.consentStatus, ConsentStatus.confirmed);
      expect(const Contact(id: '1', name: 'A', phone: '+1').consentStatus, ConsentStatus.pending);
    });

    test('initial is safe for empty names', () {
      const contact = Contact(id: '1', name: 'Ana', phone: '+1');
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
    test('serializes to the backend body and omits a missing message', () {
      expect(
        const SosAlert(latitude: -23.5, longitude: -46.6, message: 'help').toJson(),
        {'latitude': -23.5, 'longitude': -46.6, 'mensagem': 'help'},
      );
      expect(const SosAlert(latitude: 1, longitude: 2).toJson(), {'latitude': 1, 'longitude': 2});
    });
  });

  group('UserProfile', () {
    test('round-trips through JSON and tolerates missing fields', () {
      const p = UserProfile(name: 'N', email: 'e@x', phone: '1', protectionId: '#AS');
      expect(UserProfile.fromJson(p.toJson()), p);
      expect(UserProfile.fromJson(const {}), UserProfile.empty);
      expect(p.copyWith(name: 'M').name, 'M');
    });

    test('fromApi maps the backend user', () {
      final p = UserProfile.fromApi(const {
        'id': 'u-1',
        'nome_completo': 'Ana Silva',
        'email': 'ana@example.com',
        'telefone_pessoal': '+5511900000000',
        'criado_em': '2026-05-01T11:00:00Z',
      });
      expect(
        p,
        const UserProfile(name: 'Ana Silva', email: 'ana@example.com', phone: '+5511900000000', protectionId: 'u-1'),
      );
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
