import 'package:alerta_seguro/data/repositories/auth_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/auth/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login success sets loggedIn and returns the profile', () async {
    final c = AuthController(FakeAuthRepository());
    var notified = 0;
    c.addListener(() => notified++);

    final profile = await c.login(email: 'a@x', password: 'pw');

    expect(c.loggedIn, isTrue);
    expect(c.loading, isFalse);
    expect(profile.email, 'a@x');
    expect(notified, 2); // loading on, loading off
  });

  test('login failure rethrows and stays logged out', () async {
    final c = AuthController(FakeAuthRepository());
    await expectLater(c.login(email: '', password: ''), throwsA(isA<InvalidCredentialsException>()));
    expect(c.loggedIn, isFalse);
    expect(c.loading, isFalse);
  });

  test('logout', () async {
    final c = AuthController(FakeAuthRepository());
    await c.login(email: 'a@x', password: 'pw');
    c.logout();
    expect(c.loggedIn, isFalse);
  });
}
