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

/// Delivery of an alert by the server's WhatsApp worker (Regra 04).
enum AlertDelivery {
  pending('PENDENTE'),
  sent('ENVIADO'),
  failed('ERRO');

  const AlertDelivery(this.api);

  final String api;

  bool get isFinal => this != pending;
}

/// Body of `GET /sos/alertas/{id}`.
@immutable
class AlertStatus {
  const AlertStatus(this.delivery, {this.attempts = 0});

  /// Throws [FormatException] for an unknown `status_envio`.
  factory AlertStatus.fromApi(Map<String, dynamic> json) {
    final api = json['status_envio'];
    final delivery = AlertDelivery.values.where((d) => d.api == api).firstOrNull;
    if (delivery == null) throw FormatException('status_envio desconhecido: $api');
    return AlertStatus(delivery, attempts: (json['tentativas'] as num?)?.toInt() ?? 0);
  }

  final AlertDelivery delivery;
  final int attempts;

  @override
  bool operator ==(Object other) => other is AlertStatus && other.delivery == delivery && other.attempts == attempts;

  @override
  int get hashCode => Object.hash(delivery, attempts);

  @override
  String toString() => 'AlertStatus($delivery, $attempts)';
}
