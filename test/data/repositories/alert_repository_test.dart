import 'package:alerta_seguro/data/models/sos_alert.dart';
import 'package:alerta_seguro/data/repositories/alert_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_dio_adapter.dart';

void main() {
  const alert = SosAlert(latitude: 1, longitude: 2, message: 'help');

  test('HttpAlertRepository posts the alert to /sos/alertas and returns its id', () async {
    final adapter = StubDioAdapter(status: 201, body: {'id': 'a', 'status_envio': 'PENDENTE', 'criado_em': 'x'});
    final id = await HttpAlertRepository(stubDio(adapter)).send(alert);

    expect(id, 'a');
    expect(adapter.requests.single.path, '/sos/alertas');
    expect(adapter.requests.single.data, alert.toJson());
  });

  test('HttpAlertRepository rejects a created alert without id', () {
    final repo = HttpAlertRepository(stubDio(StubDioAdapter(status: 201, body: {'status_envio': 'PENDENTE'})));
    expect(repo.send(alert), throwsA(isA<RepositoryException>()));
  });

  test('HttpAlertRepository reads the delivery status of an alert', () async {
    final adapter = StubDioAdapter(
      body: {'id': 'a', 'status_envio': 'ENVIADO', 'tentativas': 2, 'criado_em': '2026-11-10T04:00:00Z'},
    );
    final status = await HttpAlertRepository(stubDio(adapter)).status('a');

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/sos/alertas/a');
    expect(status, const AlertStatus(AlertDelivery.sent, attempts: 2));
  });

  test('HttpAlertRepository maps 404 and unknown statuses to RepositoryException', () {
    expect(
      HttpAlertRepository(stubDio(StubDioAdapter(status: 404, body: {'detail': 'Alerta não encontrado.'}))).status('a'),
      throwsA(isA<RepositoryException>()),
    );
    expect(
      HttpAlertRepository(stubDio(StubDioAdapter(body: {'status_envio': 'OUTRO', 'tentativas': 0}))).status('a'),
      throwsA(isA<RepositoryException>()),
    );
  });

  test('HttpAlertRepository shows the backend message on 422', () {
    const detail = 'Cadastre ao menos um contato ativo com consentimento.';
    final repo = HttpAlertRepository(stubDio(StubDioAdapter(status: 422, body: {'detail': detail})));
    expect(repo.send(alert), throwsA(isA<RepositoryException>().having((e) => e.message, 'message', detail)));
  });

  test('HttpAlertRepository maps 401 to UnauthorizedException', () {
    final repo = HttpAlertRepository(stubDio(StubDioAdapter(status: 401)));
    expect(repo.send(alert), throwsA(isA<UnauthorizedException>()));
  });

  test('HttpAlertRepository uses a generic message for validation lists and server errors', () {
    final list = HttpAlertRepository(
      stubDio(
        StubDioAdapter(
          status: 422,
          body: {
            'detail': [
              {'msg': 'x'},
            ],
          },
        ),
      ),
    );
    expect(
      list.send(alert),
      throwsA(isA<RepositoryException>().having((e) => e.message, 'message', contains('servidor'))),
    );
    expect(HttpAlertRepository(stubDio(StubDioAdapter(status: 503))).send(alert), throwsA(isA<RepositoryException>()));
  });

  test('FakeAlertRepository records sent alerts and plays the given statuses', () async {
    final repo = FakeAlertRepository(
      statuses: const [AlertStatus(AlertDelivery.pending), AlertStatus(AlertDelivery.sent, attempts: 1)],
    );
    final id = await repo.send(alert);

    expect(repo.sent, [alert]);
    expect(await repo.status(id), const AlertStatus(AlertDelivery.pending));
    expect(await repo.status(id), const AlertStatus(AlertDelivery.sent, attempts: 1));
    expect(await repo.status(id), const AlertStatus(AlertDelivery.sent, attempts: 1)); // the last one repeats
  });
}
