import 'dart:ui';

import 'package:alerta_seguro/data/models/risk_region.dart';
import 'package:alerta_seguro/data/repositories/region_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_dio_adapter.dart';

void main() {
  const se = {
    'id': '3550308-se',
    'nome': 'Sé',
    'centroide': {'latitude': -23.55, 'longitude': -46.63},
    'score': 72,
    'cor_hex': '#E53935',
    'raio_metros': 1200,
  };

  group('HttpRegionRepository', () {
    test('fetchNearby gets /mapa/regioes with latitude, longitude and raio', () async {
      final adapter = StubDioAdapter(body: [se]);
      final regions = await HttpRegionRepository(stubDio(adapter)).fetchNearby(lat: -23.5, lng: -46.6);

      expect(regions, [
        const RiskRegion(
          id: '3550308-se',
          name: 'Sé',
          center: (lat: -23.55, lng: -46.63),
          score: 72,
          color: Color(0xFFE53935),
          radiusMeters: 1200,
        ),
      ]);
      expect(adapter.requests.single.path, '/mapa/regioes');
      expect(adapter.requests.single.queryParameters, {'latitude': -23.5, 'longitude': -46.6, 'raio': 10000});
    });

    test('maps 401 to UnauthorizedException and other failures to RepositoryException', () {
      expect(
        HttpRegionRepository(stubDio(StubDioAdapter(status: 401))).fetchNearby(lat: 0, lng: 0),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(
        HttpRegionRepository(stubDio(StubDioAdapter(status: 500))).fetchNearby(lat: 0, lng: 0),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('an invalid color is a server error', () {
      final adapter = StubDioAdapter(
        body: [
          {...se, 'cor_hex': 'vermelho'},
        ],
      );
      expect(
        HttpRegionRepository(stubDio(adapter)).fetchNearby(lat: 0, lng: 0),
        throwsA(isA<RepositoryException>().having((e) => e.message, 'message', 'Resposta inválida do servidor.')),
      );
    });
  });

  test('FakeRegionRepository returns districts around the point, in every band', () async {
    final regions = await FakeRegionRepository().fetchNearby(lat: -23.55, lng: -46.63);

    expect(regions.map((r) => r.band).toSet(), RiskBand.values.toSet());
    for (final r in regions) {
      expect(r.center.lat, closeTo(-23.55, .1));
      expect(r.center.lng, closeTo(-46.63, .1));
    }
  });
}
