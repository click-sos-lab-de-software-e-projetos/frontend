import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Dio adapter that records requests and answers with a canned JSON response.
class StubDioAdapter implements HttpClientAdapter {
  StubDioAdapter({this.status = 200, this.body});

  int status;
  Object? body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio stubDio(StubDioAdapter adapter) => Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;
