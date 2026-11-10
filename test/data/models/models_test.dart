import 'dart:ui';

import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/models/region_feedback.dart';
import 'package:alerta_seguro/data/models/risk_region.dart';
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
      const p = UserProfile(name: 'N', email: 'e@x', phone: '1', protectionId: '#AS', sosMessage: 'Socorro');
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
        'mensagem_sos': 'Me liga agora',
      });
      expect(
        p,
        const UserProfile(
          name: 'Ana Silva',
          email: 'ana@example.com',
          phone: '+5511900000000',
          protectionId: 'u-1',
          sosMessage: 'Me liga agora',
        ),
      );
      expect(UserProfile.fromApi(const {'mensagem_sos': null}).sosMessage, '');
    });
  });

  group('SosSettings', () {
    test('defaults, JSON round-trip and copyWith', () {
      const s = SosSettings();
      expect(s.silentAlert, isTrue);
      expect(SosSettings.fromJson(s.toJson()), s);
      expect(s.copyWith(silentAlert: false).silentAlert, isFalse);
    });
  });

  test('RiskRegion bands follow the backend thresholds', () {
    RiskBand band(int score) => RiskRegion(
          id: 'x',
          name: 'X',
          center: (lat: 0, lng: 0),
          score: score,
          color: const Color(0xFF000000),
          radiusMeters: 1,
        ).band;

    expect([
      band(0),
      band(33),
      band(34),
      band(66),
      band(67),
      band(100),
    ], [
      RiskBand.low,
      RiskBand.low,
      RiskBand.medium,
      RiskBand.medium,
      RiskBand.high,
      RiskBand.high,
    ]);
  });

  group('RegionFeedback', () {
    test('sends the API category and the trimmed text, omitting it when empty', () {
      expect(
        const RegionFeedback(FeedbackCategory.lighting, '  Rua escura  ').toJson(),
        {'categoria': 'ILUMINACAO', 'texto': 'Rua escura'},
      );
      expect(const RegionFeedback(FeedbackCategory.lowPolicing, '  ').toJson(), {'categoria': 'POLICIAMENTO'});
    });

    test('"Outro" needs a text and the text has at most 500 characters', () {
      expect(const RegionFeedback(FeedbackCategory.other, ' ').error, RegionFeedback.otherNeedsText);
      expect(RegionFeedback(FeedbackCategory.robbery, 'x' * 501).error, RegionFeedback.tooLong);
      expect(RegionFeedback(FeedbackCategory.robbery, 'x' * 500).error, isNull);
      expect(const RegionFeedback(FeedbackCategory.other, 'Buraco').error, isNull);
    });
  });
}
