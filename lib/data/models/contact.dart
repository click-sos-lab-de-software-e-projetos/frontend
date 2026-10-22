import 'package:flutter/foundation.dart';

@immutable
class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
    this.alertEnabled = true,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        name: json['name'] as String,
        relation: json['relation'] as String? ?? 'Contato',
        phone: json['phone'] as String,
        alertEnabled: json['alertEnabled'] as bool? ?? true,
      );

  final String id;
  final String name;
  final String relation;
  final String phone;
  final bool alertEnabled;

  /// First letter of the name, or `?` when the name is blank.
  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relation': relation,
        'phone': phone,
        'alertEnabled': alertEnabled,
      };

  Contact copyWith({String? name, String? relation, String? phone, bool? alertEnabled}) => Contact(
        id: id,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        phone: phone ?? this.phone,
        alertEnabled: alertEnabled ?? this.alertEnabled,
      );

  @override
  bool operator ==(Object other) =>
      other is Contact &&
      other.id == id &&
      other.name == name &&
      other.relation == relation &&
      other.phone == phone &&
      other.alertEnabled == alertEnabled;

  @override
  int get hashCode => Object.hash(id, name, relation, phone, alertEnabled);

  @override
  String toString() => 'Contact($id, $name, $relation, $phone, alertEnabled: $alertEnabled)';
}
