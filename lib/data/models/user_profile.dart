import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({required this.name, required this.email, required this.phone, required this.protectionId});

  static const empty = UserProfile(name: '', email: '', phone: '', protectionId: '');

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        protectionId: json['protectionId'] as String? ?? '',
      );

  final String name;
  final String email;
  final String phone;
  final String protectionId;

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'phone': phone, 'protectionId': protectionId};

  UserProfile copyWith({String? name, String? email, String? phone, String? protectionId}) => UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        protectionId: protectionId ?? this.protectionId,
      );

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.name == name &&
      other.email == email &&
      other.phone == phone &&
      other.protectionId == protectionId;

  @override
  int get hashCode => Object.hash(name, email, phone, protectionId);
}
