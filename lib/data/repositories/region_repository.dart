import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/community_alert.dart';
import '../models/risk_region.dart';
import 'repository_exception.dart';

abstract interface class RegionRepository {
  /// Districts whose border is within [radiusMeters] of the point, nearest first.
  /// Public: works without a session.
  Future<List<RiskRegion>> fetchNearby({required double lat, required double lng, int radiusMeters = maxRadius});

  /// Community alerts of the last 24 hours within [radiusMeters], newest first. Public.
  Future<List<CommunityAlert>> fetchAlerts({required double lat, required double lng, int radiusMeters = maxRadius});

  /// Creates an alert at the user's position; it does not change the risk map. Needs a session.
  Future<CommunityAlert> createAlert(NewAlert alert);

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
        options: AuthInterceptor.public,
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
  Future<List<CommunityAlert>> fetchAlerts({
    required double lat,
    required double lng,
    int radiusMeters = RegionRepository.maxRadius,
  }) async {
    try {
      final r = await _dio.get<List<dynamic>>(
        '/mapa/alertas',
        queryParameters: {'latitude': lat, 'longitude': lng, 'raio': radiusMeters},
        options: AuthInterceptor.public,
      );
      return (r.data ?? const [])
          .map((e) => CommunityAlert.fromApi(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw RepositoryException.fromDio(e, 'Não foi possível carregar os alertas.');
    } on FormatException catch (e) {
      throw RepositoryException('Resposta inválida do servidor.', cause: e);
    }
  }

  @override
  Future<CommunityAlert> createAlert(NewAlert alert) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/mapa/alertas', data: alert.toJson());
      return CommunityAlert.fromApi(r.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw RepositoryException('Confira a categoria e o texto (até ${NewAlert.maxLength} caracteres).', cause: e);
      }
      throw RepositoryException.fromDio(e, 'Não foi possível criar o alerta.');
    } on FormatException catch (e) {
      throw RepositoryException('Resposta inválida do servidor.', cause: e);
    }
  }
}

/// A few districts around the requested point (demo mode).
class FakeRegionRepository implements RegionRepository {
  final List<({double lat, double lng})> requests = [];
  final List<NewAlert> created = [];

  /// Alerts returned by [fetchAlerts]; [createAlert] adds to it.
  final List<CommunityAlert> alerts = [];

  @override
  Future<List<CommunityAlert>> fetchAlerts({
    required double lat,
    required double lng,
    int radiusMeters = RegionRepository.maxRadius,
  }) async =>
      List.of(alerts);

  @override
  Future<CommunityAlert> createAlert(NewAlert alert) async {
    created.add(alert);
    final saved = CommunityAlert(
      id: 'alerta-${created.length}',
      category: alert.category,
      text: alert.text.trim().isEmpty ? null : alert.text.trim(),
      position: alert.position,
      createdAt: DateTime.now(),
    );
    alerts.insert(0, saved);
    return saved;
  }

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
