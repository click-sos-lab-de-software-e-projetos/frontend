import 'package:flutter/foundation.dart';

/// An occurrence plotted on the heat map, as returned by `GET /occurrences`.
@immutable
class Occurrence {
  const Occurrence({required this.lat, required this.lng, required this.severity, required this.type});

  factory Occurrence.fromJson(Map<String, dynamic> json) => Occurrence(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        severity: (json['severity'] as num?)?.toInt() ?? 1,
        type: json['type'] as String? ?? '',
      );

  final double lat;
  final double lng;

  /// 1 (low) .. 3 (high).
  final int severity;
  final String type;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'severity': severity, 'type': type};

  Occurrence copyWith({double? lat, double? lng, int? severity, String? type}) => Occurrence(
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        severity: severity ?? this.severity,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      other is Occurrence && other.lat == lat && other.lng == lng && other.severity == severity && other.type == type;

  @override
  int get hashCode => Object.hash(lat, lng, severity, type);

  @override
  String toString() => 'Occurrence($lat, $lng, severity: $severity, type: $type)';
}
