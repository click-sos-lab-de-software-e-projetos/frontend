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
  });
}
