import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/core/services/whatsapp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizePhone', () {
    test('adds the Brazilian country code', () {
      expect(WhatsAppService.normalizePhone('(11) 99122-3847'), '5511991223847');
      expect(WhatsAppService.normalizePhone('11 3333-4444'), '551133334444');
    });

    test('keeps numbers that already start with 55', () {
      expect(WhatsAppService.normalizePhone('55 11 99122-3847'), '5511991223847');
      expect(WhatsAppService.normalizePhone('+55 (11) 98230-1122'), '5511982301122');
    });

    test('does not confuse area code 55 (RS) with the country code', () {
      expect(WhatsAppService.normalizePhone('(55) 99999-8888'), '5555999998888');
    });

    test('drops the trunk prefix 0', () {
      expect(WhatsAppService.normalizePhone('011 99122-3847'), '5511991223847');
    });

    test('keeps other countries typed with +', () {
      expect(WhatsAppService.normalizePhone('+1 (415) 555-0100'), '14155550100');
    });
  });

  test('chatUri encodes the message', () {
    expect(
      WhatsAppService.chatUri('(11) 99122-3847', 'Olá! a&b').toString(),
      'https://wa.me/5511991223847?text=Ol%C3%A1!%20a%26b',
    );
  });

  test('mapsLink', () {
    expect(WhatsAppService.mapsLink((lat: -23.5, lng: -46.6)), 'https://maps.google.com/?q=-23.5,-46.6');
  });

  test('open launches the wa.me URI', () async {
    Uri? launched;
    final service = WhatsAppService(
      launcher: (uri) async {
        launched = uri;
        return true;
      },
    );

    expect(await service.open('11 99122-3847', 'oi'), isTrue);
    expect(launched.toString(), 'https://wa.me/5511991223847?text=oi');
  });

  test('FakeLocationService returns the configured position', () async {
    expect(await FakeLocationService().currentPosition(), isNull);
    expect(await FakeLocationService((lat: 1, lng: 2)).currentPosition(), (lat: 1.0, lng: 2.0));
  });
}
