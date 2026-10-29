import 'package:alerta_seguro/core/config/env.dart';
import 'package:alerta_seguro/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const env = Env(apiBaseUrl: 'https://api.test', useFakeApi: false);

  test('uses the configured base URL', () {
    expect(buildDio(env).options.baseUrl, 'https://api.test');
  });

  test('logs only in debug and never logs bodies', () {
    expect(buildDio(env, debug: false).interceptors.whereType<LogInterceptor>(), isEmpty);

    final log = buildDio(env, debug: true).interceptors.whereType<LogInterceptor>().single;
    expect(log.requestBody, isFalse);
    expect(log.responseBody, isFalse);
  });

  test('Env defaults to the fake API', () {
    expect(const Env.fromEnvironment().useFakeApi, isTrue);
  });
}
