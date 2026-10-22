import 'package:dio/dio.dart';

import '../models/sos_alert.dart';
import 'repository_exception.dart';

abstract interface class AlertRepository {
  Future<void> send(SosAlert alert);
}

class HttpAlertRepository implements AlertRepository {
  HttpAlertRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> send(SosAlert alert) async {
    try {
      await _dio.post<void>('/alerts', data: alert.toJson());
    } on DioException catch (e) {
      throw RepositoryException('Não foi possível enviar o alerta ao servidor.', cause: e);
    }
  }
}

class FakeAlertRepository implements AlertRepository {
  final List<SosAlert> sent = [];

  @override
  Future<void> send(SosAlert alert) async => sent.add(alert);
}
