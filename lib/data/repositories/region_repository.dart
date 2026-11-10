import 'package:dio/dio.dart';

import '../models/risk_region.dart';
import 'repository_exception.dart';

abstract interface class RegionRepository {
  /// Districts whose border is within [radiusMeters] of the point, nearest first.
  /// Throws [UnauthorizedException] without a session.
  Future<List<RiskRegion>> fetchNearby({required double lat, required double lng, int radiusMeters = maxRadius});

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
}

/// A few districts around the requested point (demo mode).
class FakeRegionRepository implements RegionRepository {
  final List<({double lat, double lng})> requests = [];

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
