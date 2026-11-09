import 'package:dio/dio.dart';

import '../models/sos_alert.dart';
import 'repository_exception.dart';

abstract interface class AlertRepository {
  /// Registers the alert on the server. Throws [UnauthorizedException] without
  /// a session and [RepositoryException] with the backend message otherwise
  /// (e.g. no active contact with consent).
  Future<void> send(SosAlert alert);
}

class HttpAlertRepository implements AlertRepository {
  HttpAlertRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> send(SosAlert alert) async {
    try {
      await _dio.post<void>('/sos/alertas', data: alert.toJson());
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e, 'Não foi possível enviar o alerta ao servidor.');
    }
  }
}

class FakeAlertRepository implements AlertRepository {
  final List<SosAlert> sent = [];

  @override
  Future<void> send(SosAlert alert) async => sent.add(alert);
}
