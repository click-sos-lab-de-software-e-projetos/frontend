import 'package:alerta_seguro/data/models/occurrence_report.dart';
import 'package:alerta_seguro/data/repositories/occurrence_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/map/occurrences_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingRepo implements OccurrenceRepository {
  @override
  Future<void> report(OccurrenceReport report) => Future.error(const RepositoryException('falhou'));
}

void main() {
  test('report sends the report', () async {
    final repo = FakeOccurrenceRepository();
    final r = OccurrenceReport(address: 'A', lat: 1, lng: 2, type: 'Assédio', dateTime: DateTime(2026));

    await OccurrencesController(repo).report(r);

    expect(repo.reports, [r]);
  });

  test('report rethrows failures', () {
    expect(
      OccurrencesController(_FailingRepo())
          .report(OccurrenceReport(address: 'A', type: 'Outro', dateTime: DateTime(2026))),
      throwsA(isA<RepositoryException>()),
    );
  });
}
