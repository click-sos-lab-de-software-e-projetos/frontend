import 'package:dio/dio.dart';

import '../models/sos_alert.dart';
import 'repository_exception.dart';

abstract interface class AlertRepository {
  /// Registers the alert on the server and returns its id. Throws
  /// [UnauthorizedException] without a session and [RepositoryException] with
  /// the backend message otherwise (e.g. no active contact with consent).
  Future<String> send(SosAlert alert);

  /// Delivery status of an alert of the session's user.
  Future<AlertStatus> status(String id);
}

class HttpAlertRepository implements AlertRepository {
  HttpAlertRepository(this._dio);

  final Dio _dio;

  @override
  Future<String> send(SosAlert alert) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/sos/alertas', data: alert.toJson());
      final id = r.data?['id'];
      if (id is! String || id.isEmpty) throw const RepositoryException('Resposta inválida do servidor.');
      return id;
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e, 'Não foi possível enviar o alerta ao servidor.');
    }
  }

  @override
  Future<AlertStatus> status(String id) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/sos/alertas/${Uri.encodeComponent(id)}');
      return AlertStatus.fromApi(r.data ?? const {});
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e, 'Não foi possível consultar o envio do alerta.');
    } on FormatException catch (e) {
      throw RepositoryException('Resposta inválida do servidor.', cause: e);
    }
  }
}

/// Records sent alerts. [status] plays [statuses] in order and then repeats the last one.
class FakeAlertRepository implements AlertRepository {
  FakeAlertRepository({this.statuses = const [AlertStatus(AlertDelivery.sent, attempts: 1)]});

  final List<SosAlert> sent = [];
  List<AlertStatus> statuses;
  int _polls = 0;

  @override
  Future<String> send(SosAlert alert) async {
    sent.add(alert);
    return 'fake-alert-${sent.length}';
  }

  @override
  Future<AlertStatus> status(String id) async {
    final i = _polls < statuses.length ? _polls : statuses.length - 1;
    _polls++;
    return statuses[i];
  }
}
