import 'package:click_sos/core/network/session.dart';
import 'package:click_sos/core/network/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('start saves the token and clear deletes it', () async {
    final store = MemoryTokenStore();
    final session = Session(store: store);

    session.start('abc');
    expect(await store.read(), 'abc');

    session.clear();
    expect(await store.read(), isNull);
  });

  test('restore starts the session with the saved token', () async {
    final session = Session(store: MemoryTokenStore('saved'));
    var notified = 0;
    session.addListener(() => notified++);

    await session.restore();

    expect(session.token, 'saved');
    expect(notified, 1);
  });

  test('restore without a saved token stays logged out', () async {
    final session = Session(store: MemoryTokenStore());
    await session.restore();
    expect(session.isActive, isFalse);
  });
}
