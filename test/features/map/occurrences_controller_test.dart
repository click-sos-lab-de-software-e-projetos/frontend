import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/data/models/occurrence.dart';
import 'package:alerta_seguro/data/models/occurrence_report.dart';
import 'package:alerta_seguro/data/repositories/occurrence_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/map/occurrences_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingRepo implements OccurrenceRepository {
  @override
  Future<List<Occurrence>> fetchNearby({required double lat, required double lng, int radiusMeters = 5000}) =>
      Future.error(const RepositoryException('falhou'));

  @override
  Future<void> report(OccurrenceReport report) => Future.error(const RepositoryException('falhou'));
}

void main() {
  test('load uses the current position and fills occurrences', () async {
    final c = OccurrencesController(FakeOccurrenceRepository(), FakeLocationService((lat: 1, lng: 2)));
    expect(await c.load(), isNull);
    expect(c.center, (lat: 1.0, lng: 2.0));
    expect(c.occurrences, hasLength(40));
    expect(c.loading, isFalse);
  });

  test('load falls back to the default center without location', () async {
    final c = OccurrencesController(FakeOccurrenceRepository(), FakeLocationService());
    await c.load();
    expect(c.center, OccurrencesController.defaultCenter);
  });

  test('load returns the error message on failure', () async {
    final c = OccurrencesController(_FailingRepo(), FakeLocationService());
    expect(await c.load(), 'falhou');
    expect(c.occurrences, isEmpty);
    expect(c.loading, isFalse);
  });

  test('report sends and plots reports with coordinates', () async {
    final repo = FakeOccurrenceRepository();
    final c = OccurrencesController(repo, FakeLocationService());
    final r = OccurrenceReport(address: 'A', lat: 1, lng: 2, type: 'Assédio', dateTime: DateTime(2026));

    await c.report(r);
    await c.report(OccurrenceReport(address: 'B', type: 'Outro', dateTime: DateTime(2026)));

    expect(repo.reports, hasLength(2));
    expect(c.occurrences, [const Occurrence(lat: 1, lng: 2, severity: 3, type: 'Assédio')]);
  });

  test('report rethrows failures', () {
    final c = OccurrencesController(_FailingRepo(), FakeLocationService());
    expect(
      c.report(OccurrenceReport(address: 'A', type: 'Outro', dateTime: DateTime(2026))),
      throwsA(isA<RepositoryException>()),
    );
  });
}
