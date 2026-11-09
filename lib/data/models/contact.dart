import 'package:flutter/foundation.dart';

/// Trusted contact, as returned by `/contatos`.
@immutable
class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.alertEnabled = true,
    this.consentedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        name: json['nome'] as String,
        phone: json['telefone_whatsapp'] as String,
        alertEnabled: json['ativo'] as bool? ?? true,
        consentedAt: switch (json['consentido_em']) {
          final String s => DateTime.parse(s),
          _ => null,
        },
      );

  final String id;
  final String name;

  /// E.164, e.g. `+5511900000001`.
  final String phone;
  final bool alertEnabled;

  /// When the contact agreed to receive alerts; `null` while pending. The
  /// backend only sends SOS alerts to active contacts that consented.
  final DateTime? consentedAt;

  bool get hasConsent => consentedAt != null;

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
      );

  @override
  bool operator ==(Object other) =>
      other is Contact &&
      other.id == id &&
      other.name == name &&
      other.phone == phone &&
      other.alertEnabled == alertEnabled &&
      other.consentedAt == consentedAt;

  @override
  int get hashCode => Object.hash(id, name, phone, alertEnabled, consentedAt);

  @override
  String toString() => 'Contact($id, $name, $phone, alertEnabled: $alertEnabled, consentedAt: $consentedAt)';
}
