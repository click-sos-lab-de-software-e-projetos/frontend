import 'package:flutter/material.dart';

import '../../core/services/geo_point.dart';

/// Alert categories accepted by the backend, with the map icon.
enum AlertCategory {
  lighting('ILUMINACAO', 'Iluminação', Icons.lightbulb_outline),
  robbery('ASSALTO', 'Assalto', Icons.report_gmailerrorred),
  harassment('ASSEDIO', 'Assédio', Icons.front_hand_outlined),
  lowMovement('MOVIMENTO', 'Pouco movimento', Icons.directions_walk),
  lowPolicing('POLICIAMENTO', 'Falta de policiamento', Icons.local_police_outlined),
  other('OUTRO', 'Outro', Icons.warning_amber_rounded);

  const AlertCategory(this.api, this.label, this.icon);

  final String api;
  final String label;
  final IconData icon;

  static AlertCategory fromApi(String api) =>
      values.firstWhere((c) => c.api == api, orElse: () => throw FormatException('Categoria inválida', api));
}

/// An alert being created at the user's position (`POST /mapa/alertas`).
@immutable
class NewAlert {
  const NewAlert(this.category, this.position, [this.text = '']);

  static const maxLength = 500;
  static const otherNeedsText = 'Descreva o problema para a categoria Outro.';
  static const tooLong = 'Use até $maxLength caracteres.';

  final AlertCategory category;
  final GeoPoint position;
  final String text;

  /// User-facing validation message, or null when it can be sent.
  String? get error {
    final t = text.trim();
    if (t.length > maxLength) return tooLong;
    if (category == AlertCategory.other && t.isEmpty) return otherNeedsText;
    return null;
  }

  Map<String, dynamic> toJson() => {
        'categoria': category.api,
        if (text.trim().isNotEmpty) 'texto': text.trim(),
        'latitude': position.lat,
        'longitude': position.lng,
      };

  @override
  bool operator ==(Object other) =>
      other is NewAlert && other.category == category && other.position == position && other.text == text;

  @override
  int get hashCode => Object.hash(category, position, text);
}

/// A community alert shown on the map for 24 hours, as returned by `/mapa/alertas`.
@immutable
class CommunityAlert {
  const CommunityAlert({
    required this.id,
    required this.category,
    required this.position,
    required this.createdAt,
    this.text,
  });

  /// Throws [FormatException] when a field is missing or invalid.
  factory CommunityAlert.fromApi(Map<String, dynamic> json) {
    try {
      return CommunityAlert(
        id: json['id'] as String,
        category: AlertCategory.fromApi(json['categoria'] as String),
        text: json['texto'] as String?,
        position: (lat: (json['latitude'] as num).toDouble(), lng: (json['longitude'] as num).toDouble()),
        createdAt: DateTime.parse(json['criado_em'] as String),
      );
    } on TypeError {
      throw FormatException('Alerta inválido', json);
    }
  }

  static const lifetime = Duration(hours: 24);

  final String id;
  final AlertCategory category;
  final String? text;
  final GeoPoint position;
  final DateTime createdAt;

  /// "agora", "há 5 min", "há 3 h".
  static String age(DateTime createdAt, DateTime now) {
    final d = now.difference(createdAt);
    if (d.inMinutes < 1) return 'agora';
    if (d.inHours < 1) return 'há ${d.inMinutes} min';
    return 'há ${d.inHours} h';
  }

  @override
  bool operator ==(Object other) =>
      other is CommunityAlert &&
      other.id == id &&
      other.category == category &&
      other.text == text &&
      other.position == position &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, category, text, position, createdAt);
}
