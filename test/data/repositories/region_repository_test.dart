import 'dart:ui';

import 'package:alerta_seguro/data/models/community_alert.dart';
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

  group('alerts', () {
    const json = {
      'id': 'a1',
      'categoria': 'ILUMINACAO',
      'texto': 'Rua escura',
      'latitude': -23.5,
      'longitude': -46.6,
      'criado_em': '2026-11-12T10:00:00Z',
    };
    final alert = CommunityAlert(
      id: 'a1',
      category: AlertCategory.lighting,
      text: 'Rua escura',
      position: (lat: -23.5, lng: -46.6),
      createdAt: DateTime.utc(2026, 11, 12, 10),
    );

    test('fetchAlerts gets /mapa/alertas without a session', () async {
      final adapter = StubDioAdapter(body: [json]);

      expect(await HttpRegionRepository(stubDio(adapter)).fetchAlerts(lat: -23.5, lng: -46.6), [alert]);
      expect(adapter.requests.single.path, '/mapa/alertas');
      expect(adapter.requests.single.queryParameters, {'latitude': -23.5, 'longitude': -46.6, 'raio': 10000});
      expect(adapter.requests.single.extra['public'], isTrue);
    });

    test('createAlert posts the alert and returns what was saved', () async {
      final adapter = StubDioAdapter(status: 201, body: json);
      const created = NewAlert(AlertCategory.lighting, (lat: -23.5, lng: -46.6), 'Rua escura');

      expect(await HttpRegionRepository(stubDio(adapter)).createAlert(created), alert);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/mapa/alertas');
      expect(adapter.requests.single.data, created.toJson());
    });

    test('createAlert explains 422', () {
      const created = NewAlert(AlertCategory.robbery, (lat: 0, lng: 0));
      expect(
        HttpRegionRepository(stubDio(StubDioAdapter(status: 422))).createAlert(created),
        throwsA(isA<RepositoryException>().having((e) => e.message, 'message', contains('500'))),
      );
    });

    test('the fake records what was created and lists it first', () async {
      final repo = FakeRegionRepository();
      const created = NewAlert(AlertCategory.robbery, (lat: 1, lng: 2), ' ');

      final saved = await repo.createAlert(created);

      expect(repo.created, [created]);
      expect((saved.category, saved.position, saved.text), (AlertCategory.robbery, (lat: 1.0, lng: 2.0), null));
      expect(await repo.fetchAlerts(lat: 0, lng: 0), [saved]);
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
