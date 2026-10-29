import 'package:alerta_seguro/data/models/sos_alert.dart';
import 'package:alerta_seguro/data/repositories/alert_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_dio_adapter.dart';

void main() {
  const alert = SosAlert(lat: 1, lng: 2, message: 'help', userId: '#AS-1');

  test('HttpAlertRepository posts the alert', () async {
    final adapter = StubDioAdapter();
    await HttpAlertRepository(stubDio(adapter)).send(alert);

    expect(adapter.requests.single.path, '/alerts');
    expect(adapter.requests.single.data, alert.toJson());
  });

  test('HttpAlertRepository wraps failures in RepositoryException', () {
    final repo = HttpAlertRepository(stubDio(StubDioAdapter(status: 503)));
    expect(repo.send(alert), throwsA(isA<RepositoryException>()));
  });

  test('FakeAlertRepository records sent alerts', () async {
    final repo = FakeAlertRepository();
    await repo.send(alert);
    expect(repo.sent, [alert]);
  });
}
