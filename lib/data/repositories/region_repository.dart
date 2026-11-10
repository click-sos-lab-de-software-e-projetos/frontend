import 'package:dio/dio.dart';

import '../models/region_feedback.dart';
import '../models/risk_region.dart';
import 'repository_exception.dart';

abstract interface class RegionRepository {
  /// Districts whose border is within [radiusMeters] of the point, nearest first.
  /// Throws [UnauthorizedException] without a session.
  Future<List<RiskRegion>> fetchNearby({required double lat, required double lng, int radiusMeters = maxRadius});

  /// Sends a community feedback about the region; it stays pending and does not change the map.
  Future<void> sendFeedback(String regionId, RegionFeedback feedback);

  /// Largest radius the backend accepts.
  static const maxRadius = 10000;
}

class HttpRegionRepository implements RegionRepository {
  HttpRegionRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<RiskRegion>> fetchNearby({
    required double lat,
    required double lng,
    int radiusMeters = RegionRepository.maxRadius,
  }) async {
    try {
      final r = await _dio.get<List<dynamic>>(
        '/mapa/regioes',
        queryParameters: {'latitude': lat, 'longitude': lng, 'raio': radiusMeters},
      );
      return (r.data ?? const [])
          .map((e) => RiskRegion.fromApi(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e, 'Não foi possível carregar o mapa de risco.');
    } on FormatException catch (e) {
      throw RepositoryException('Resposta inválida do servidor.', cause: e);
    }
  }

  @override
  Future<void> sendFeedback(String regionId, RegionFeedback feedback) async {
    try {
      await _dio.post<void>('/mapa/regioes/${Uri.encodeComponent(regionId)}/feedbacks', data: feedback.toJson());
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 404:
          throw RepositoryException('Região não encontrada.', cause: e);
        case 422:
          throw RepositoryException(
            'Confira a categoria e o texto (até ${RegionFeedback.maxLength} caracteres).',
            cause: e,
          );
      }
      throw RepositoryException.fromDio(e, 'Não foi possível enviar o feedback.');
    }
  }
}

/// A few districts around the requested point (demo mode).
class FakeRegionRepository implements RegionRepository {
  final List<({double lat, double lng})> requests = [];
  final List<({String regionId, RegionFeedback feedback})> feedbacks = [];

  @override
  Future<void> sendFeedback(String regionId, RegionFeedback feedback) async =>
      feedbacks.add((regionId: regionId, feedback: feedback));

  static const _districts = [
    ('Sé', 0.0, 0.0, 82),
    ('República', .005, -.012, 71),
    ('Bela Vista', -.012, -.008, 52),
    ('Liberdade', -.017, .003, 45),
    ('Cambuci', -.015, .02, 38),
    ('Consolação', 0.0, -.025, 28),
    ('Pari', .025, .01, 18),
  ];

  @override
  Future<List<RiskRegion>> fetchNearby({
    required double lat,
    required double lng,
    int radiusMeters = RegionRepository.maxRadius,
  }) async {
    requests.add((lat: lat, lng: lng));
    return [
      for (final (name, dLat, dLng, score) in _districts)
        RiskRegion(
          id: 'fake-${name.toLowerCase()}',
          name: name,
          center: (lat: lat + dLat, lng: lng + dLng),
          score: score,
          color: RiskBand.of(score).color,
          radiusMeters: 900,
        ),
    ];
  }
}
