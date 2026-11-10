import 'package:alerta_seguro/data/models/occurrence_report.dart';
import 'package:alerta_seguro/data/repositories/occurrence_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_dio_adapter.dart';

void main() {
  final report =
      OccurrenceReport(address: 'Rua A', lat: 1, lng: 2, type: 'Outro', dateTime: DateTime(2026, 1, 2, 3, 4));

  group('HttpOccurrenceRepository', () {
    test('report posts the JSON body', () async {
      final adapter = StubDioAdapter(status: 201);
      await HttpOccurrenceRepository(stubDio(adapter)).report(report);

      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, report.toJson());
    });

    test('wraps failures in RepositoryException', () {
      final repo = HttpOccurrenceRepository(stubDio(StubDioAdapter(status: 500)));
      expect(repo.report(report), throwsA(isA<RepositoryException>()));
    });
  });

  group('FakeOccurrenceRepository', () {
    test('records reports', () async {
      final repo = FakeOccurrenceRepository();
      await repo.report(report);
      expect(repo.reports, [report]);
    });
  });
}
