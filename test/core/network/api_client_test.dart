import 'package:click_sos/core/config/env.dart';
import 'package:click_sos/core/network/api_client.dart';
import 'package:click_sos/core/network/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_dio_adapter.dart';

void main() {
  const env = Env(apiBaseUrl: 'https://api.test/api/v1', useFakeApi: false);

  Dio build(Session session, StubDioAdapter adapter) =>
      buildDio(env, session: session, debug: false)..httpClientAdapter = adapter;

  test('joins the base URL path with request paths', () async {
    final adapter = StubDioAdapter();
    await build(Session(), adapter).get<void>('/auth/me');
    expect(adapter.requests.single.uri.toString(), 'https://api.test/api/v1/auth/me');
  });

  test('logs only in debug and never logs bodies or headers', () {
    expect(buildDio(env, debug: false).interceptors.whereType<LogInterceptor>(), isEmpty);

    final log = buildDio(env, debug: true).interceptors.whereType<LogInterceptor>().single;
    expect(log.requestBody, isFalse);
    expect(log.responseBody, isFalse);
    expect(log.requestHeader, isFalse);
  });

  test('sends the session token as Bearer only while logged in', () async {
    final session = Session();
    final adapter = StubDioAdapter();
    final dio = build(session, adapter);

    await dio.get<void>('/contatos');
    expect(adapter.requests.last.headers, isNot(contains('Authorization')));

    session.start('jwt');
    await dio.get<void>('/contatos');
    expect(adapter.requests.last.headers['Authorization'], 'Bearer jwt');
  });

  test('a 401 for the current token ends the session', () async {
    final session = Session()..start('jwt');
    final dio = build(session, StubDioAdapter(status: 401));

    await expectLater(dio.get<void>('/contatos'), throwsA(isA<DioException>()));
    expect(session.isActive, isFalse);
  });

  test('a 401 on a request without a token (wrong login) does not touch the session', () async {
    final session = Session();
    var notified = false;
    session.addListener(() => notified = true);
    final dio = build(session, StubDioAdapter(status: 401));

    await expectLater(dio.post<void>('/auth/login'), throwsA(isA<DioException>()));
    expect(notified, isFalse);
  });

  test('public requests (login) never send the token, so a 401 keeps the session', () async {
    final session = Session()..start('jwt');
    final adapter = StubDioAdapter(status: 401);
    final dio = build(session, adapter);

    await expectLater(dio.post<void>('/auth/login', options: AuthInterceptor.public), throwsA(isA<DioException>()));
    expect(adapter.requests.single.headers, isNot(contains('Authorization')));
    expect(session.isActive, isTrue);
  });

  test('Env defaults to the fake API and the emulator host', () {
    expect(const Env.fromEnvironment().useFakeApi, isTrue);
    expect(Env.defaultApiBaseUrl, 'http://10.0.2.2:8000/api/v1');
  });

  test('Session notifies only on changes', () {
    final session = Session();
    var notified = 0;
    session.addListener(() => notified++);
    session
      ..start('a')
      ..start('a')
      ..clear()
      ..clear();
    expect(notified, 2);
  });
}
