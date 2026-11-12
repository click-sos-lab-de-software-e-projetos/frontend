import 'package:click_sos/core/network/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SecureTokenStore writes, reads and deletes the token', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const store = SecureTokenStore();

    expect(await store.read(), isNull);
    await store.write('abc');
    expect(await store.read(), 'abc');
    await store.delete();
    expect(await store.read(), isNull);
  });
}
