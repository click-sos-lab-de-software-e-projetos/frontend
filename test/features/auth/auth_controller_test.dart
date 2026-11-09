import 'package:alerta_seguro/core/network/session.dart';
import 'package:alerta_seguro/data/models/user_profile.dart';
import 'package:alerta_seguro/data/repositories/auth_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/auth/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _MeFails extends FakeAuthRepository {
  @override
  Future<UserProfile> me() => Future.error(const RepositoryException('offline'));
}

void main() {
  test('login starts the session and returns the profile', () async {
    final session = Session();
    final c = AuthController(FakeAuthRepository(), session);
    var notified = 0;
    c.addListener(() => notified++);

    final profile = await c.login(email: ' a@x ', password: 'pw');

    expect(c.loggedIn, isTrue);
    expect(session.token, isNotNull);
    expect(c.loading, isFalse);
    expect(profile.email, 'a@x');
    expect(notified, 3); // loading on, session started, loading off
  });

  test('login failure rethrows and stays logged out', () async {
    final c = AuthController(FakeAuthRepository(), Session());
    await expectLater(c.login(email: '', password: ''), throwsA(isA<InvalidCredentialsException>()));
    expect(c.loggedIn, isFalse);
    expect(c.loading, isFalse);
  });

  test('a failing profile request ends the session', () async {
    final session = Session();
    final c = AuthController(_MeFails(), session);
    await expectLater(c.login(email: 'a@x', password: 'pw'), throwsA(isA<RepositoryException>()));
    expect(session.isActive, isFalse);
  });

  test('register creates the account and logs in', () async {
    final c = AuthController(FakeAuthRepository(), Session());
    final profile = await c.register(name: ' Ana ', email: 'ana@x.com', phone: '+5511900000000', password: '12345678');

    expect(profile.name, 'Ana');
    expect(c.loggedIn, isTrue);
  });

  test('register failure stays logged out', () async {
    final repo = FakeAuthRepository();
    await repo.register(name: 'Ana', email: 'ana@x.com', phone: '+1', password: '12345678');
    final c = AuthController(repo, Session());

    await expectLater(
      c.register(name: 'Ana', email: 'ana@x.com', phone: '+1', password: '12345678'),
      throwsA(isA<EmailInUseException>()),
    );
    expect(c.loggedIn, isFalse);
  });

  test('logout clears the session and follows external session changes', () async {
    final session = Session();
    final c = AuthController(FakeAuthRepository(), session);
    await c.login(email: 'a@x', password: 'pw');
    c.logout();
    expect(c.loggedIn, isFalse);

    var notified = false;
    c.addListener(() => notified = true);
    session.start('other');
    expect(c.loggedIn, isTrue);
    expect(notified, isTrue);
  });
}
