import 'package:alerta_seguro/data/models/occurrence.dart';
import 'package:alerta_seguro/data/models/occurrence_report.dart';
import 'package:alerta_seguro/data/repositories/occurrence_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_dio_adapter.dart';

void main() {
  final report =
      OccurrenceReport(address: 'Rua A', lat: 1, lng: 2, type: 'Outro', dateTime: DateTime(2026, 1, 2, 3, 4));

  group('HttpOccurrenceRepository', () {
    test('fetchNearby sends lat/lng/radius and parses the list', () async {
      final adapter = StubDioAdapter(
        body: [
          {'lat': 1, 'lng': 2, 'severity': 3, 'type': 'Assédio'},
        ],
      );
      final result = await HttpOccurrenceRepository(stubDio(adapter)).fetchNearby(lat: 1, lng: 2, radiusMeters: 100);

      expect(result, [const Occurrence(lat: 1, lng: 2, severity: 3, type: 'Assédio')]);
      expect(adapter.requests.single.path, '/occurrences');
      expect(adapter.requests.single.queryParameters, {'lat': 1.0, 'lng': 2.0, 'radius': 100});
    });

    test('report posts the JSON body', () async {
      final adapter = StubDioAdapter(status: 201);
      await HttpOccurrenceRepository(stubDio(adapter)).report(report);

      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, report.toJson());
    });

    test('wraps failures in RepositoryException', () {
      final repo = HttpOccurrenceRepository(stubDio(StubDioAdapter(status: 500)));
      expect(repo.fetchNearby(lat: 0, lng: 0), throwsA(isA<RepositoryException>()));
      expect(repo.report(report), throwsA(isA<RepositoryException>()));
    });
  });

  group('FakeOccurrenceRepository', () {
    test('generates a deterministic heat map around the point', () async {
      final repo = FakeOccurrenceRepository();
      final a = await repo.fetchNearby(lat: -23.55, lng: -46.63);
      final b = await repo.fetchNearby(lat: -23.55, lng: -46.63);

      expect(a, hasLength(40));
      expect(a, b);
      for (final o in a) {
        expect(o.lat, closeTo(-23.55, .02));
        expect(o.lng, closeTo(-46.63, .02));
        expect(o.severity, inInclusiveRange(1, 3));
      }
    });

    test('records reports', () async {
      final repo = FakeOccurrenceRepository();
      await repo.report(report);
      expect(repo.reports, [report]);
    });
  });
}
