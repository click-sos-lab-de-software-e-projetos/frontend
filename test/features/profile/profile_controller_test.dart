import 'package:alerta_seguro/core/network/session.dart';
import 'package:alerta_seguro/data/models/user_profile.dart';
import 'package:alerta_seguro/data/repositories/auth_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/profile/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _Me extends FakeAuthRepository {
  _Me(this.result);

  final Future<UserProfile> Function() result;

  @override
  Future<UserProfile> me() => result();
}

const _ana = UserProfile(name: 'Ana', email: 'ana@x.com', phone: '+5511900000000', protectionId: 'u1');

void main() {
  test('starts empty and updates trimmed fields', () {
    final c = ProfileController();
    expect(c.profile, UserProfile.empty);

    var notified = 0;
    c.addListener(() => notified++);
    c.update(name: ' Ana ', email: 'a@x');
    expect(c.profile, const UserProfile(name: 'Ana', email: 'a@x', phone: '', protectionId: ''));

    c.update(name: 'Ana'); // no change → no notification
    expect(notified, 1);
  });

  test('replace swaps the whole profile', () {
    final c = ProfileController();
    const p = UserProfile(name: 'N', email: 'e', phone: 'p', protectionId: '#1');
    c.replace(p);
    expect(c.profile, p);
  });

  test('resets when the session ends', () {
    final session = Session()..start('t');
    final c = ProfileController(UserProfile.empty, session);
    c.replace(const UserProfile(name: 'N', email: 'e', phone: 'p', protectionId: '#1'));

    session.clear();
    expect(c.profile, UserProfile.empty);
  });

  test('load fills the profile of a restored session', () async {
    final c = ProfileController(UserProfile.empty, Session()..start('saved'));
    await c.load(_Me(() async => _ana));
    expect(c.profile, _ana);
  });

  test('load with a rejected token ends the session', () async {
    final session = Session()..start('expired');
    final c = ProfileController(UserProfile.empty, session);

    await c.load(_Me(() => Future.error(const UnauthorizedException())));

    expect(session.isActive, isFalse);
    expect(c.profile, UserProfile.empty);
  });

  test('load offline keeps the session', () async {
    final session = Session()..start('saved');
    final c = ProfileController(UserProfile.empty, session);

    await c.load(_Me(() => Future.error(const RepositoryException('offline'))));

    expect(session.token, 'saved');
  });

  test('load ignores a profile that arrives after logout', () async {
    final session = Session()..start('saved');
    final c = ProfileController(UserProfile.empty, session);

    await c.load(
      _Me(() async {
        session.clear();
        return _ana;
      }),
    );

    expect(c.profile, UserProfile.empty);
  });

  test('saveSosMessage trims, saves and keeps the server answer', () async {
    final auth = FakeAuthRepository();
    await auth.login(email: 'ana@x.com', password: '1');
    final c = ProfileController(_ana);

    await c.saveSosMessage(auth, '  Me liga  ');

    expect(c.profile.sosMessage, 'Me liga');
    expect((await auth.me()).sosMessage, 'Me liga');
  });
}
