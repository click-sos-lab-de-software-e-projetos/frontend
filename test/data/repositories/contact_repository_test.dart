import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/repositories/contact_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_dio_adapter.dart';

void main() {
  const json = {
    'id': 'c-1',
    'nome': 'Ana',
    'telefone_whatsapp': '+5511900000001',
    'ativo': true,
    'consentido_em': null,
    'criado_em': '2026-05-01T11:00:00Z',
  };
  const contact = Contact(id: 'c-1', name: 'Ana', phone: '+5511900000001');

  group('HttpContactRepository', () {
    test('list gets /contatos', () async {
      final adapter = StubDioAdapter(body: [json]);
      expect(await HttpContactRepository(stubDio(adapter)).list(), [contact]);
      expect(adapter.requests.single.path, '/contatos');
      expect(adapter.requests.single.method, 'GET');
    });

    test('create posts nome and telefone_whatsapp', () async {
      final adapter = StubDioAdapter(status: 201, body: json);
      expect(await HttpContactRepository(stubDio(adapter)).create(name: 'Ana', phone: '+5511900000001'), contact);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {'nome': 'Ana', 'telefone_whatsapp': '+5511900000001'});
    });

    test('update patches only the given fields', () async {
      final adapter = StubDioAdapter(body: {...json, 'ativo': false});
      final updated = await HttpContactRepository(stubDio(adapter)).update('c-1', alertEnabled: false);

      expect(updated.alertEnabled, isFalse);
      expect(adapter.requests.single.path, '/contatos/c-1');
      expect(adapter.requests.single.method, 'PATCH');
      expect(adapter.requests.single.data, {'ativo': false});
    });

    test('delete calls DELETE /contatos/{id}', () async {
      final adapter = StubDioAdapter(status: 204);
      await HttpContactRepository(stubDio(adapter)).delete('c-1');
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, '/contatos/c-1');
    });

    test('maps 409 to the active-contact limit message', () {
      final repo = HttpContactRepository(stubDio(StubDioAdapter(status: 409, body: {'detail': 'x'})));
      expect(
        repo.create(name: 'Ana', phone: '+5511900000001'),
        throwsA(
          isA<RepositoryException>().having((e) => e.message, 'message', 'Limite de 3 contatos ativos atingido.'),
        ),
      );
    });

    test('requestConsentLink posts to /contatos/{id}/consentimento and returns the url', () async {
      final adapter = StubDioAdapter(
        status: 201,
        body: {'url': 'https://consentimento.example/#token=abc', 'expira_em': '2026-05-08T12:00:00Z'},
      );
      expect(
        await HttpContactRepository(stubDio(adapter)).requestConsentLink('c-1'),
        'https://consentimento.example/#token=abc',
      );
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/contatos/c-1/consentimento');
    });

    test('requestConsentLink maps 409 to already consented', () {
      final repo = HttpContactRepository(stubDio(StubDioAdapter(status: 409, body: {'detail': 'x'})));
      expect(
        repo.requestConsentLink('c-1'),
        throwsA(
          isA<RepositoryException>().having((e) => e.message, 'message', 'Este contato já confirmou o consentimento.'),
        ),
      );
    });

    test('maps 401 to UnauthorizedException', () {
      expect(HttpContactRepository(stubDio(StubDioAdapter(status: 401))).list(), throwsA(isA<UnauthorizedException>()));
    });
  });

  group('FakeContactRepository', () {
    test('creates contacts without consent and enforces the active limit', () async {
      final repo = FakeContactRepository();
      for (var i = 0; i < 3; i++) {
        expect((await repo.create(name: 'C$i', phone: '+5511900000000')).hasConsent, isFalse);
      }
      expect(repo.create(name: 'C3', phone: '+5511900000000'), throwsA(isA<RepositoryException>()));

      final first = (await repo.list()).first;
      await repo.update(first.id, alertEnabled: false);
      await repo.create(name: 'C3', phone: '+5511900000000');
      expect(repo.update(first.id, alertEnabled: true), throwsA(isA<RepositoryException>()));

      await repo.delete(first.id);
      expect(await repo.list(), hasLength(3));
    });

    test('a new phone clears consent and refusal, a new name keeps them', () async {
      final repo = FakeContactRepository([
        Contact(id: 'ok', name: 'O', phone: '+5511900000001', consentedAt: DateTime.utc(2026)),
        Contact(id: 'no', name: 'N', phone: '+5511900000002', refusedAt: DateTime.utc(2026)),
      ]);

      expect((await repo.update('ok', name: 'Olga')).hasConsent, isTrue);
      expect((await repo.update('ok', phone: '+5511900000001')).hasConsent, isTrue);
      final moved = await repo.update('ok', phone: '+5511911111111');
      expect((moved.name, moved.consentStatus), ('Olga', ConsentStatus.pending));
      expect((await repo.update('no', phone: '+5511922222222')).consentStatus, ConsentStatus.pending);
    });

    test('requestConsentLink returns a link for pending contacts only', () async {
      final repo = FakeContactRepository([
        const Contact(id: 'p', name: 'P', phone: '+1'),
        Contact(id: 'ok', name: 'O', phone: '+2', consentedAt: DateTime.utc(2026)),
      ]);
      expect(await repo.requestConsentLink('p'), contains('#token='));
      expect(repo.requestConsentLink('ok'), throwsA(isA<RepositoryException>()));
    });
  });
}
