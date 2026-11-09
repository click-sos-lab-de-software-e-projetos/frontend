import 'package:flutter/foundation.dart';

/// Body of `POST /sos/alertas`. The user comes from the token.
@immutable
class SosAlert {
  const SosAlert({required this.latitude, required this.longitude, this.message});

  final double latitude;
  final double longitude;
  final String? message;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (message != null) 'mensagem': message,
      };

  @override
  bool operator ==(Object other) =>
      other is SosAlert && other.latitude == latitude && other.longitude == longitude && other.message == message;

  @override
  int get hashCode => Object.hash(latitude, longitude, message);

  @override
  String toString() => 'SosAlert($latitude, $longitude, $message)';
}
