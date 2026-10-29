import 'package:alerta_seguro/data/models/user_profile.dart';
import 'package:alerta_seguro/data/repositories/auth_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_dio_adapter.dart';

void main() {
  group('HttpAuthRepository', () {
    test('posts credentials and parses the profile', () async {
      final adapter = StubDioAdapter(body: {'name': 'Ana', 'phone': '1', 'protectionId': '#AS-1'});
      final profile = await HttpAuthRepository(stubDio(adapter)).login(email: 'a@x', password: 'pw');

      expect(profile, const UserProfile(name: 'Ana', email: 'a@x', phone: '1', protectionId: '#AS-1'));
      expect(adapter.requests.single.path, '/auth/login');
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {'email': 'a@x', 'password': 'pw'});
    });

    test('throws InvalidCredentialsException on 401', () {
      final repo = HttpAuthRepository(stubDio(StubDioAdapter(status: 401)));
      expect(repo.login(email: 'a@x', password: 'bad'), throwsA(isA<InvalidCredentialsException>()));
    });

    test('throws RepositoryException on server errors', () {
      final repo = HttpAuthRepository(stubDio(StubDioAdapter(status: 500)));
      expect(
        repo.login(email: 'a@x', password: 'pw'),
        throwsA(isA<RepositoryException>().having((e) => e, 'type', isNot(isA<InvalidCredentialsException>()))),
      );
    });
  });

  group('FakeAuthRepository', () {
    test('accepts any non-empty email and password', () async {
      final profile = await FakeAuthRepository().login(email: ' me@x ', password: '1');
      expect(profile.email, 'me@x');
    });

    test('rejects empty email or password', () {
      final repo = FakeAuthRepository();
      expect(repo.login(email: '', password: '1'), throwsA(isA<InvalidCredentialsException>()));
      expect(repo.login(email: 'me@x', password: ''), throwsA(isA<InvalidCredentialsException>()));
    });
  });
}
