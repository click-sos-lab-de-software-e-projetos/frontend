import 'package:flutter/foundation.dart';

@immutable
class SosSettings {
  const SosSettings({this.message = defaultMessage, this.silentAlert = true});

  static const defaultMessage =
      '[Alerta Seguro] Preciso de ajuda urgente! Minha localização em tempo real foi ativada em:';
  static const maxMessageLength = 160;

  factory SosSettings.fromJson(Map<String, dynamic> json) => SosSettings(
        message: json['message'] as String? ?? defaultMessage,
        silentAlert: json['silentAlert'] as bool? ?? true,
      );

  final String message;
  final bool silentAlert;

  Map<String, dynamic> toJson() => {'message': message, 'silentAlert': silentAlert};

  SosSettings copyWith({String? message, bool? silentAlert}) =>
      SosSettings(message: message ?? this.message, silentAlert: silentAlert ?? this.silentAlert);

  @override
  bool operator ==(Object other) =>
      other is SosSettings && other.message == message && other.silentAlert == silentAlert;

  @override
  int get hashCode => Object.hash(message, silentAlert);
}
