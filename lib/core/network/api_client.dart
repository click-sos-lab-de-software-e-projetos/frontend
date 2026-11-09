import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'session.dart';

Dio buildDio(Env env, {Session? session, bool debug = kDebugMode}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  if (session != null) dio.interceptors.add(AuthInterceptor(session));
  if (debug) {
    // Never log bodies or headers: they may contain passwords, the token or the user's location.
    dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false, requestHeader: false));
  }
  return dio;
}

/// Sends the session token as a Bearer header and ends the session when the
/// server rejects it (expired or revoked token).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session);

  /// Requests with this flag (login, sign-up) never carry the token, so their
  /// 401 cannot end the current session.
  static final public = Options(extra: {_publicKey: true});
  static const _publicKey = 'public';

  final Session _session;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.token;
    if (token != null && options.extra[_publicKey] != true) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sentToken = err.requestOptions.headers['Authorization'] == 'Bearer ${_session.token}';
    if (err.response?.statusCode == 401 && _session.isActive && sentToken) _session.clear();
    handler.next(err);
  }
}
