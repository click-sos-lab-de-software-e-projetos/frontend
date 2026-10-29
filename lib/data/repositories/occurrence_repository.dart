import 'dart:math';

import 'package:dio/dio.dart';

import '../models/occurrence.dart';
import '../models/occurrence_report.dart';
import 'repository_exception.dart';

abstract interface class OccurrenceRepository {
  Future<List<Occurrence>> fetchNearby({required double lat, required double lng, int radiusMeters = 5000});

  Future<void> report(OccurrenceReport report);
}

class HttpOccurrenceRepository implements OccurrenceRepository {
  HttpOccurrenceRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Occurrence>> fetchNearby({required double lat, required double lng, int radiusMeters = 5000}) async {
    try {
      final r = await _dio.get<List<dynamic>>(
        '/occurrences',
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radiusMeters},
      );
      return (r.data ?? const [])
          .map((e) => Occurrence.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw RepositoryException('Não foi possível carregar as ocorrências.', cause: e);
    }
  }

  @override
  Future<void> report(OccurrenceReport report) async {
    try {
      await _dio.post<void>('/occurrences', data: report.toJson());
    } on DioException catch (e) {
      throw RepositoryException('Não foi possível registrar a ocorrência.', cause: e);
    }
  }
}

/// Generates a deterministic random heat map around the requested point.
class FakeOccurrenceRepository implements OccurrenceRepository {
  FakeOccurrenceRepository({this.seed = 7, this.count = 40});

  final int seed;
  final int count;
  final List<OccurrenceReport> reports = [];

  @override
  Future<List<Occurrence>> fetchNearby({required double lat, required double lng, int radiusMeters = 5000}) async {
    final rnd = Random(seed);
    return List.generate(
      count,
      (_) => Occurrence(
        lat: lat + (rnd.nextDouble() - .5) * .04,
        lng: lng + (rnd.nextDouble() - .5) * .04,
        severity: 1 + rnd.nextInt(3),
        type: 'Ocorrência',
      ),
      growable: false,
    );
  }

  @override
  Future<void> report(OccurrenceReport report) async => reports.add(report);
}
