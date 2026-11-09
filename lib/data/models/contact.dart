import 'package:flutter/foundation.dart';

enum ConsentStatus { pending, confirmed, refused }

DateTime? _date(Object? v) => v is String ? DateTime.parse(v) : null;

/// Trusted contact, as returned by `/contatos`.
@immutable
class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.alertEnabled = true,
    this.consentedAt,
    this.refusedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        name: json['nome'] as String,
        phone: json['telefone_whatsapp'] as String,
        alertEnabled: json['ativo'] as bool? ?? true,
        consentedAt: _date(json['consentido_em']),
        refusedAt: _date(json['recusado_em']),
      );

  final String id;
  final String name;

  /// E.164, e.g. `+5511900000001`.
  final String phone;
  final bool alertEnabled;

  /// When the contact agreed to receive alerts; `null` while pending. The
  /// backend only sends SOS alerts to active contacts that consented.
  final DateTime? consentedAt;

  /// When the contact refused through the consent link; cleared if they
  /// accept a later link.
  final DateTime? refusedAt;

  bool get hasConsent => consentedAt != null;

  ConsentStatus get consentStatus => hasConsent
      ? ConsentStatus.confirmed
      : refusedAt != null
          ? ConsentStatus.refused
          : ConsentStatus.pending;

  /// First letter of the name, or `?` when the name is blank.
  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  Contact copyWith({String? name, String? phone, bool? alertEnabled}) => Contact(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        alertEnabled: alertEnabled ?? this.alertEnabled,
        consentedAt: consentedAt,
        refusedAt: refusedAt,
      );

  @override
  bool operator ==(Object other) =>
      other is Contact &&
      other.id == id &&
      other.name == name &&
      other.phone == phone &&
      other.alertEnabled == alertEnabled &&
      other.consentedAt == consentedAt &&
      other.refusedAt == refusedAt;

  @override
  int get hashCode => Object.hash(id, name, phone, alertEnabled, consentedAt, refusedAt);

  @override
  String toString() =>
      'Contact($id, $name, $phone, alertEnabled: $alertEnabled, consentedAt: $consentedAt, refusedAt: $refusedAt)';
}
