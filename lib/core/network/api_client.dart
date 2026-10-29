import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';

Dio buildDio(Env env, {bool debug = kDebugMode}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  if (debug) {
    // Never log bodies: they may contain passwords or the user's location.
    dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
  }
  return dio;
}
