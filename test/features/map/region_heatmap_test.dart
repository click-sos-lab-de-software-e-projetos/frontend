import 'dart:math';
import 'dart:ui';

import 'package:click_sos/data/models/risk_region.dart';
import 'package:click_sos/features/map/widgets/region_heatmap.dart';
import 'package:flutter_test/flutter_test.dart';

RiskRegion _region(int score, {double lng = -46.6333}) => RiskRegion(
      id: 'r$score',
      name: 'r$score',
      center: (lat: -23.5505, lng: lng),
      score: score,
      color: const Color(0xFF000000),
      radiusMeters: 1000,
    );

const _zoom = 14;

/// Tile and pixel of the region center at [_zoom].
(int, int, int) _tileOf(RiskRegion r) {
  final scale = 256 * pow(2, _zoom);
  final sinLat = sin(r.center.lat * pi / 180);
  final x = (r.center.lng + 180) / 360 * scale;
  final y = (.5 - log((1 + sinLat) / (1 - sinLat)) / (4 * pi)) * scale;
  return (x ~/ 256, y ~/ 256, ((y % 256).floor() * 256 + (x % 256).floor()) * 4);
}

List<int> _centerPixel(RiskRegion r) {
  final (tx, ty, i) = _tileOf(r);
  final pixels = RiskHeatTiles.heatPixels([r], tx, ty, _zoom)!;
  return pixels.sublist(i, i + 4);
}

void main() {
  test('high risk is red and more opaque than low risk, which is green', () {
    final high = _centerPixel(_region(100));
    final low = _centerPixel(_region(0));

    expect(high[0], greaterThan(high[1]));
    expect(low[1], greaterThan(low[0]));
    expect(high[3], greaterThan(low[3]));
    expect(low[3], greaterThanOrEqualTo(130), reason: 'safe areas must stand out on the map');
  });

  test('tiles far from every district are empty', () {
    final (tx, ty, _) = _tileOf(_region(100));

    expect(RiskHeatTiles.heatPixels([_region(100)], tx + 20, ty, _zoom), isNull);
  });

  test('the layer key changes only when the districts change', () {
    final a = [_region(10), _region(90, lng: -46.6)];

    expect(riskHeatLayer(a).key, riskHeatLayer([...a]).key);
    expect(riskHeatLayer(a).key, isNot(riskHeatLayer([_region(10)]).key));
  });
}
