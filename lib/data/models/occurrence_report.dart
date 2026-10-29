import 'package:flutter/foundation.dart';

/// Body of `POST /occurrences`.
@immutable
class OccurrenceReport {
  const OccurrenceReport({
    required this.address,
    required this.type,
    required this.dateTime,
    this.lat,
    this.lng,
  });

  factory OccurrenceReport.fromJson(Map<String, dynamic> json) => OccurrenceReport(
        address: json['address'] as String,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        type: json['type'] as String,
        dateTime: DateTime.parse(json['datetime'] as String).toLocal(),
      );

  final String address;
  final double? lat;
  final double? lng;
  final String type;
  final DateTime dateTime;

  Map<String, dynamic> toJson() => {
        'address': address,
        'lat': lat,
        'lng': lng,
        'type': type,
        // UTC ISO-8601 (e.g. 2026-10-22T01:30:00.000Z) so the server gets an unambiguous instant.
        'datetime': dateTime.toUtc().toIso8601String(),
      };

  OccurrenceReport copyWith({String? address, double? lat, double? lng, String? type, DateTime? dateTime}) =>
      OccurrenceReport(
        address: address ?? this.address,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        type: type ?? this.type,
        dateTime: dateTime ?? this.dateTime,
      );

  @override
  bool operator ==(Object other) =>
      other is OccurrenceReport &&
      other.address == address &&
      other.lat == lat &&
      other.lng == lng &&
      other.type == type &&
      other.dateTime == dateTime;

  @override
  int get hashCode => Object.hash(address, lat, lng, type, dateTime);
}
