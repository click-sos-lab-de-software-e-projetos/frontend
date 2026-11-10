import 'package:flutter/foundation.dart';

/// Device-only SOS preferences. The SOS message lives on the account (see `UserProfile.sosMessage`).
@immutable
class SosSettings {
  const SosSettings({this.silentAlert = true});

  factory SosSettings.fromJson(Map<String, dynamic> json) =>
      SosSettings(silentAlert: json['silentAlert'] as bool? ?? true);

  final bool silentAlert;

  Map<String, dynamic> toJson() => {'silentAlert': silentAlert};

  SosSettings copyWith({bool? silentAlert}) => SosSettings(silentAlert: silentAlert ?? this.silentAlert);

  @override
  bool operator ==(Object other) => other is SosSettings && other.silentAlert == silentAlert;

  @override
  int get hashCode => silentAlert.hashCode;
}
