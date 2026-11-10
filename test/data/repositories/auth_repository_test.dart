import 'package:alerta_seguro/data/models/user_profile.dart';
import 'package:alerta_seguro/data/repositories/auth_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_dio_adapter.dart';

void main() {
  const user = {
    'id': 'u-1',
    'nome_completo': 'Ana',
    'email': 'a@x.com',
    'telefone_pessoal': '+5511900000000',
    'criado_em': '2026-05-01T11:00:00Z',
  };
  const profile = UserProfile(name: 'Ana', email: 'a@x.com', phone: '+5511900000000', protectionId: 'u-1');

  group('HttpAuthRepository', () {
    test('login posts email/senha and returns the access token', () async {
      final adapter = StubDioAdapter(body: {'access_token': 'jwt', 'token_type': 'bearer', 'expires_in': 86400});
      final token = await HttpAuthRepository(stubDio(adapter)).login(email: 'a@x.com', password: 'pw');

      expect(token, 'jwt');
      expect(adapter.requests.single.path, '/auth/login');
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {'email': 'a@x.com', 'senha': 'pw'});
      expect(adapter.requests.single.extra['public'], isTrue);
    });

    test('login throws InvalidCredentialsException on 401', () {
      final repo = HttpAuthRepository(stubDio(StubDioAdapter(status: 401)));
      expect(repo.login(email: 'a@x.com', password: 'bad'), throwsA(isA<InvalidCredentialsException>()));
    });

    test('login throws RepositoryException on server errors', () {
      final repo = HttpAuthRepository(stubDio(StubDioAdapter(status: 500)));
      expect(
        repo.login(email: 'a@x.com', password: 'pw'),
        throwsA(isA<RepositoryException>().having((e) => e, 'type', isNot(isA<InvalidCredentialsException>()))),
      );
    });

    test('register posts the backend fields and parses the user', () async {
      final adapter = StubDioAdapter(status: 201, body: user);
      final created = await HttpAuthRepository(stubDio(adapter))
          .register(name: 'Ana', email: 'a@x.com', phone: '+5511900000000', password: '12345678');

      expect(created, profile);
      expect(adapter.requests.single.path, '/auth/cadastro');
      expect(adapter.requests.single.data, {
        'nome_completo': 'Ana',
        'email': 'a@x.com',
        'telefone_pessoal': '+5511900000000',
        'senha': '12345678',
      });
    });

    test('register maps 409 to EmailInUseException', () {
      final repo = HttpAuthRepository(stubDio(StubDioAdapter(status: 409, body: {'detail': 'E-mail já cadastrado.'})));
      expect(
        repo.register(name: 'Ana', email: 'a@x.com', phone: '+5511900000000', password: '12345678'),
        throwsA(isA<EmailInUseException>()),
      );
    });

    test('me gets the profile and maps 401 to UnauthorizedException', () async {
      final adapter = StubDioAdapter(body: user);
      expect(await HttpAuthRepository(stubDio(adapter)).me(), profile);
      expect(adapter.requests.single.path, '/auth/me');

      final repo = HttpAuthRepository(stubDio(StubDioAdapter(status: 401)));
      expect(repo.me(), throwsA(isA<UnauthorizedException>()));
    });

    test('updateSosMessage patches mensagem_sos and returns the saved profile', () async {
      final adapter = StubDioAdapter(body: {...user, 'mensagem_sos': 'Me liga'});
      final saved = await HttpAuthRepository(stubDio(adapter)).updateSosMessage('Me liga');

      expect(saved.sosMessage, 'Me liga');
      expect(adapter.requests.single.path, '/auth/me');
      expect(adapter.requests.single.method, 'PATCH');
      expect(adapter.requests.single.data, {'mensagem_sos': 'Me liga'});
    });

    test('updateSosMessage explains a 422', () {
      final repo = HttpAuthRepository(stubDio(StubDioAdapter(status: 422)));
      expect(
        repo.updateSosMessage('x'),
        throwsA(isA<RepositoryException>().having((e) => e.message, 'message', contains('255'))),
      );
    });

    test('updateProfile patches only the given fields and returns the saved profile', () async {
      final adapter = StubDioAdapter(body: {...user, 'nome_completo': 'Bia'});
      final saved = await HttpAuthRepository(stubDio(adapter)).updateProfile(name: 'Bia');

      expect(saved.name, 'Bia');
      expect(adapter.requests.single.path, '/auth/me');
      expect(adapter.requests.single.method, 'PATCH');
      expect(adapter.requests.single.data, {'nome_completo': 'Bia'});

      final both = StubDioAdapter(body: user);
      await HttpAuthRepository(stubDio(both)).updateProfile(name: 'Ana', phone: '+5511911111111');
      expect(both.requests.single.data, {'nome_completo': 'Ana', 'telefone_pessoal': '+5511911111111'});
    });

    test('updateProfile explains a 422', () {
      final repo = HttpAuthRepository(stubDio(StubDioAdapter(status: 422)));
      expect(
        repo.updateProfile(phone: '+1'),
        throwsA(isA<RepositoryException>().having((e) => e.message, 'message', contains('telefone'))),
      );
    });

    test('changePassword posts senha_atual/senha_nova', () async {
      final adapter = StubDioAdapter(status: 204);
      await HttpAuthRepository(stubDio(adapter)).changePassword(current: 'old', next: '12345678');

      expect(adapter.requests.single.path, '/auth/me/senha');
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {'senha_atual': 'old', 'senha_nova': '12345678'});
    });

    test('changePassword maps 400 to WrongPasswordException', () {
      final repo = HttpAuthRepository(stubDio(StubDioAdapter(status: 400)));
      expect(
        repo.changePassword(current: 'x', next: '12345678'),
        throwsA(isA<WrongPasswordException>().having((e) => e.message, 'message', 'Senha atual incorreta.')),
      );
    });
  });

  group('FakeAuthRepository', () {
    test('accepts any non-empty email and password for unknown accounts', () async {
      final repo = FakeAuthRepository();
      expect(await repo.login(email: ' me@x ', password: '1'), isNotEmpty);
      expect((await repo.me()).email, 'me@x');
    });

    test('rejects empty email or password', () {
      final repo = FakeAuthRepository();
      expect(repo.login(email: '', password: '1'), throwsA(isA<InvalidCredentialsException>()));
      expect(repo.login(email: 'me@x', password: ''), throwsA(isA<InvalidCredentialsException>()));
    });

    test('registered accounts need their password and duplicates are rejected', () async {
      final repo = FakeAuthRepository();
      await repo.register(name: 'Ana', email: 'A@x.com', phone: '+1', password: '12345678');

      expect(
        repo.register(name: 'Ana', email: 'a@x.com', phone: '+1', password: '12345678'),
        throwsA(isA<EmailInUseException>()),
      );
      expect(repo.login(email: 'a@x.com', password: 'wrong'), throwsA(isA<InvalidCredentialsException>()));
      await repo.login(email: 'a@x.com', password: '12345678');
      expect((await repo.me()).name, 'Ana');
    });

    test('updateSosMessage is kept for the logged account', () async {
      final repo = FakeAuthRepository();
      await repo.login(email: 'me@x', password: '1');

      expect((await repo.updateSosMessage('Me liga')).sosMessage, 'Me liga');
      expect((await repo.me()).sosMessage, 'Me liga');
      expect(FakeAuthRepository().updateSosMessage('x'), throwsA(isA<UnauthorizedException>()));
    });

    test('updateProfile is kept for the logged account', () async {
      final repo = FakeAuthRepository();
      await repo.register(name: 'Ana', email: 'a@x.com', phone: '+5511900000000', password: '12345678');
      await repo.login(email: 'a@x.com', password: '12345678');

      final saved = await repo.updateProfile(phone: '+5511911111111');
      expect((saved.name, saved.phone), ('Ana', '+5511911111111'));
      expect((await repo.updateProfile(name: 'Bia')).name, 'Bia');
      expect((await repo.me()).phone, '+5511911111111');
      expect(FakeAuthRepository().updateProfile(name: 'x'), throwsA(isA<UnauthorizedException>()));
    });

    test('changePassword checks the current password of registered accounts', () async {
      final repo = FakeAuthRepository();
      await repo.register(name: 'Ana', email: 'a@x.com', phone: '+1', password: '12345678');
      await repo.login(email: 'a@x.com', password: '12345678');

      expect(repo.changePassword(current: 'wrong', next: 'abcdefgh'), throwsA(isA<WrongPasswordException>()));
      await repo.changePassword(current: '12345678', next: 'abcdefgh');
      expect(repo.login(email: 'a@x.com', password: '12345678'), throwsA(isA<InvalidCredentialsException>()));
      expect(await repo.login(email: 'a@x.com', password: 'abcdefgh'), isNotEmpty);
    });

    test('me without login is unauthorized', () {
      expect(FakeAuthRepository().me(), throwsA(isA<UnauthorizedException>()));
    });
  });
}
