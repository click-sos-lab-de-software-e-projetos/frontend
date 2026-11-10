import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../core/services/geo_point.dart';

/// Risk bands of the backend score (0–100), with the backend colors.
enum RiskBand {
  low('Baixo', Color(0xFF22C55E)),
  medium('Médio', Color(0xFFEAB308)),
  high('Alto', Color(0xFFEF4444));

  const RiskBand(this.label, this.color);

  /// Green below 34, yellow from 34 to 66, red from 67 (same as the backend).
  static RiskBand of(int score) => score < 34
      ? low
      : score < 67
          ? medium
          : high;

  final String label;
  final Color color;
}

/// A district drawn on the risk map, as returned by `GET /mapa/regioes`.
@immutable
class RiskRegion {
  const RiskRegion({
    required this.id,
    required this.name,
    required this.center,
    required this.score,
    required this.color,
    required this.radiusMeters,
  });

  /// Throws [FormatException] when a field is missing or the color is not `#RRGGBB`.
  factory RiskRegion.fromApi(Map<String, dynamic> json) {
    final center = json['centroide'];
    final hex = json['cor_hex'];
    if (center is! Map || hex is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) {
      throw FormatException('Região inválida', json);
    }
    try {
      return RiskRegion(
        id: json['id'] as String,
        name: json['nome'] as String,
        center: (lat: (center['latitude'] as num).toDouble(), lng: (center['longitude'] as num).toDouble()),
        score: (json['score'] as num).toInt(),
        color: Color(0xFF000000 | int.parse(hex.substring(1), radix: 16)),
        radiusMeters: (json['raio_metros'] as num).toDouble(),
      );
    } on TypeError {
      throw FormatException('Região inválida', json);
    }
  }

  final String id;
  final String name;
  final GeoPoint center;
  final int score;
  final Color color;
  final double radiusMeters;

  RiskBand get band => RiskBand.of(score);

  @override
  bool operator ==(Object other) =>
      other is RiskRegion &&
      other.id == id &&
      other.name == name &&
      other.center == center &&
      other.score == score &&
      other.color == color &&
      other.radiusMeters == radiusMeters;

  @override
  int get hashCode => Object.hash(id, name, center, score, color, radiusMeters);

  @override
  String toString() => 'RiskRegion($id, $name, score: $score)';
}
