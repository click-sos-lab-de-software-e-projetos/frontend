import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/risk_region.dart';

const _tileSize = 256;

/// Heat reaches this many district radii, so neighbours blend into each other.
const _reach = 1.6;

/// Score colors (0, 50, 100) — the same green, yellow and red of the backend bands.
/// The green is a deep one so safe areas still stand out on the light map.
const _stops = [(0x16, 0xA3, 0x4A), (0xEA, 0xB3, 0x08), (0xEF, 0x44, 0x44)];

/// Opacity at score 0 and the extra opacity at score 100: safe areas stay clearly visible.
const _minAlpha = 140;
const _extraAlpha = 70;

/// Draws the districts as a heat map in map tiles.
///
/// Google's heatmap layer is gone from the Maps JavaScript API, so the heat is
/// painted here: each pixel mixes the scores of the nearby districts, weighted by
/// a smooth falloff in meters, and gets more opaque the higher the risk.
TileOverlay riskHeatOverlay(List<RiskRegion> regions) => TileOverlay(
      tileOverlayId: TileOverlayId('risco-${Object.hashAll(regions.map((r) => (r.id, r.score, r.radiusMeters)))}'),
      tileProvider: RiskHeatTiles(regions),
      fadeIn: false,
    );

class RiskHeatTiles implements TileProvider {
  RiskHeatTiles(this.regions);

  final List<RiskRegion> regions;

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    final pixels = heatPixels(regions, x, y, zoom ?? 0);
    return pixels == null ? TileProvider.noTile : Tile(_tileSize, _tileSize, await _png(pixels));
  }

  /// RGBA pixels of tile ([x], [y], [zoom]), or null when no district reaches it.
  static Uint8List? heatPixels(List<RiskRegion> regions, int x, int y, int zoom) {
    final scale = _tileSize * pow(2, zoom).toDouble();
    final left = x * _tileSize.toDouble();
    final top = y * _tileSize.toDouble();
    final near = [
      for (final r in regions)
        if (_project(r, scale) case final p
            when p.x + p.reach > left &&
                p.x - p.reach < left + _tileSize &&
                p.y + p.reach > top &&
                p.y - p.reach < top + _tileSize)
          p,
    ];
    if (near.isEmpty) return null;
    final out = Uint8List(_tileSize * _tileSize * 4);
    for (var py = 0; py < _tileSize; py++) {
      for (var px = 0; px < _tileSize; px++) {
        var weight = 0.0;
        var score = 0.0;
        for (final r in near) {
          final dx = left + px + .5 - r.x;
          final dy = top + py + .5 - r.y;
          final d2 = (dx * dx + dy * dy) / (r.reach * r.reach);
          if (d2 >= 1) continue;
          final w = (1 - d2) * (1 - d2);
          weight += w;
          score += w * r.score;
        }
        if (weight == 0) continue;
        final heat = score / weight / 100;
        final (red, green, blue) = _color(heat);
        final i = (py * _tileSize + px) * 4;
        out[i] = red;
        out[i + 1] = green;
        out[i + 2] = blue;
        out[i + 3] = (min(weight, 1.0) * (_minAlpha + _extraAlpha * heat)).round();
      }
    }
    return out;
  }

  /// Web Mercator pixel position and reach of [r] at the zoom of [scale].
  static ({double x, double y, double reach, int score}) _project(RiskRegion r, double scale) {
    final sinLat = sin(r.center.lat * pi / 180);
    final metersPerPixel = 2 * pi * 6378137 * cos(r.center.lat * pi / 180) / scale;
    return (
      x: (r.center.lng + 180) / 360 * scale,
      y: (.5 - log((1 + sinLat) / (1 - sinLat)) / (4 * pi)) * scale,
      reach: r.radiusMeters * _reach / metersPerPixel,
      score: r.score,
    );
  }

  static (int, int, int) _color(double heat) {
    final t = heat.clamp(0.0, 1.0) * (_stops.length - 1);
    final i = min(t.floor(), _stops.length - 2);
    final f = t - i;
    final (a, b) = (_stops[i], _stops[i + 1]);
    int mix(int p, int q) => (p + (q - p) * f).round();
    return (mix(a.$1, b.$1), mix(a.$2, b.$2), mix(a.$3, b.$3));
  }

  static Future<Uint8List> _png(Uint8List rgba) async {
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, _tileSize, _tileSize, ui.PixelFormat.rgba8888, done.complete);
    final image = await done.future;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }
}
