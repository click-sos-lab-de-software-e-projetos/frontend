import 'package:dio/dio.dart';

import '../models/occurrence_report.dart';
import 'repository_exception.dart';

abstract interface class OccurrenceRepository {
  Future<void> report(OccurrenceReport report);
}

class HttpOccurrenceRepository implements OccurrenceRepository {
  HttpOccurrenceRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> report(OccurrenceReport report) async {
    try {
      await _dio.post<void>('/occurrences', data: report.toJson());
    } on DioException catch (e) {
      throw RepositoryException('Não foi possível registrar a ocorrência.', cause: e);
    }
  }
}

/// Records reports (demo mode).
class FakeOccurrenceRepository implements OccurrenceRepository {
  final List<OccurrenceReport> reports = [];

  @override
  Future<void> report(OccurrenceReport report) async => reports.add(report);
}
