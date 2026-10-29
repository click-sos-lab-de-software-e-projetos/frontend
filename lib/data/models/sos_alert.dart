import 'package:flutter/foundation.dart';

/// Body of `POST /alerts`.
@immutable
class SosAlert {
  const SosAlert({required this.message, required this.userId, this.lat, this.lng});

  factory SosAlert.fromJson(Map<String, dynamic> json) => SosAlert(
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        message: json['message'] as String,
        userId: json['userId'] as String,
      );

  final double? lat;
  final double? lng;
  final String message;
  final String userId;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'message': message, 'userId': userId};

  @override
  bool operator ==(Object other) =>
      other is SosAlert && other.lat == lat && other.lng == lng && other.message == message && other.userId == userId;

  @override
  int get hashCode => Object.hash(lat, lng, message, userId);
}
