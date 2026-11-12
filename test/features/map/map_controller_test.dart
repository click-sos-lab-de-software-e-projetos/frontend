import 'dart:async';
import 'dart:ui';

import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/data/models/risk_region.dart';
import 'package:alerta_seguro/data/repositories/region_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/map/map_controller.dart';
import 'package:flutter_test/flutter_test.dart';

RiskRegion _region(String id) =>
    RiskRegion(id: id, name: id, center: (lat: 0, lng: 0), score: 50, color: const Color(0xFFFDD835), radiusMeters: 1);

/// Answers each request with the completer the test chooses.
class _ManualRegions extends FakeRegionRepository {
  final calls = <Completer<List<RiskRegion>>>[];

  @override
  Future<List<RiskRegion>> fetchNearby({required double lat, required double lng, int radiusMeters = 0}) {
    calls.add(Completer());
    return calls.last.future;
  }
}

class _FailingRegions extends FakeRegionRepository {
  @override
  Future<List<RiskRegion>> fetchNearby({required double lat, required double lng, int radiusMeters = 0}) =>
      Future.error(const RepositoryException('Sem internet.'));
}

const _idle = Duration(milliseconds: 1);

void main() {
  MapController build({RegionRepository? regions, LocationService? location}) => MapController(
        regions: regions ?? FakeRegionRepository(),
        location: location ?? FakeLocationService((lat: -23.5, lng: -46.6)),
        idleDelay: _idle,
      );

  test('with permission already granted it centers on the position', () async {
    final regions = FakeRegionRepository();
    final c = build(regions: regions);

    await c.init();

    expect(c.locationAllowed, isTrue);
    expect(c.center, (lat: -23.5, lng: -46.6));
    expect(regions.requests, [(lat: -23.5, lng: -46.6)]);
    expect(c.regions, isNotEmpty);
  });

  test('without permission it uses Praça da Sé and never asks (MAPM-03)', () async {
    final location = FakeLocationService((lat: 1, lng: 2))..access = LocationAccess.canAsk;
    final c = build(location: location);

    await c.init();

    expect(c.locationAllowed, isFalse);
    expect(c.center, MapController.defaultCenter);
    expect(location.requests, 0);
  });

  test('camera idle reloads only after moving more than 2 km', () async {
    final regions = FakeRegionRepository();
    final c = build(regions: regions);
    await c.init();

    c.cameraIdle((lat: -23.51, lng: -46.6)); // ~1.1 km
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(regions.requests, hasLength(1));

    c.cameraIdle((lat: -23.6, lng: -46.6)); // ~11 km
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(regions.requests.last, (lat: -23.6, lng: -46.6));
  });

  test('an older answer does not replace a newer one', () async {
    final regions = _ManualRegions();
    final c = build(regions: regions);
    unawaited(c.init());
    await pumpEventQueue();

    c.cameraIdle((lat: -23.7, lng: -46.6));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    regions.calls[1].complete([_region('new')]);
    regions.calls[0].complete([_region('old')]);
    await pumpEventQueue();

    expect(c.regions.map((r) => r.id), ['new']);
  });

  test('failure shows the message and stops loading', () async {
    final c = build(regions: _FailingRegions());
    await c.init();

    expect(c.error, 'Sem internet.');
    expect(c.loading, isFalse);
  });

  test('select shows one region and null closes it', () async {
    final c = build();
    await c.init();

    c.select(c.regions[1].id);
    expect(c.selected, c.regions[1]);

    c.select(null);
    expect(c.selected, isNull);
  });
}
