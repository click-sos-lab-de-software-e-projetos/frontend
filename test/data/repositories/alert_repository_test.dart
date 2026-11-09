import 'package:alerta_seguro/data/models/sos_alert.dart';
import 'package:alerta_seguro/data/repositories/alert_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_dio_adapter.dart';

void main() {
  const alert = SosAlert(latitude: 1, longitude: 2, message: 'help');

  test('HttpAlertRepository posts the alert to /sos/alertas', () async {
    final adapter = StubDioAdapter(status: 201, body: {'id': 'a', 'status_envio': 'PENDENTE', 'criado_em': 'x'});
    await HttpAlertRepository(stubDio(adapter)).send(alert);

    expect(adapter.requests.single.path, '/sos/alertas');
    expect(adapter.requests.single.data, alert.toJson());
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

  test('FakeAlertRepository records sent alerts', () async {
    final repo = FakeAlertRepository();
    await repo.send(alert);
    expect(repo.sent, [alert]);
  });
}
