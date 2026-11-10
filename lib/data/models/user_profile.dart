import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.protectionId,
    this.sosMessage = '',
  });

  static const empty = UserProfile(name: '', email: '', phone: '', protectionId: '');

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        protectionId: json['protectionId'] as String? ?? '',
        sosMessage: json['sosMessage'] as String? ?? '',
      );

  /// Response of `/auth/cadastro` and `/auth/me`.
  factory UserProfile.fromApi(Map<String, dynamic> json) => UserProfile(
        name: json['nome_completo'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['telefone_pessoal'] as String? ?? '',
        protectionId: json['id'] as String? ?? '',
        sosMessage: json['mensagem_sos'] as String? ?? '',
      );

  final String name;
  final String email;
  final String phone;
  final String protectionId;

  /// S.O.S. message saved in Ajustes; empty means the server's default (Regra 02).
  final String sosMessage;

  Map<String, dynamic> toJson() =>
      {'name': name, 'email': email, 'phone': phone, 'protectionId': protectionId, 'sosMessage': sosMessage};

  UserProfile copyWith({String? name, String? email, String? phone, String? protectionId, String? sosMessage}) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        protectionId: protectionId ?? this.protectionId,
        sosMessage: sosMessage ?? this.sosMessage,
      );

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.name == name &&
      other.email == email &&
      other.phone == phone &&
      other.protectionId == protectionId &&
      other.sosMessage == sosMessage;

  @override
  int get hashCode => Object.hash(name, email, phone, protectionId, sosMessage);
}
