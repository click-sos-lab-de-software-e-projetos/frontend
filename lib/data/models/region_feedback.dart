import 'package:flutter/foundation.dart';

/// Feedback categories accepted by the backend.
enum FeedbackCategory {
  lighting('ILUMINACAO', 'Iluminação'),
  robbery('ASSALTO', 'Assalto'),
  harassment('ASSEDIO', 'Assédio'),
  lowMovement('MOVIMENTO', 'Pouco movimento'),
  lowPolicing('POLICIAMENTO', 'Falta de policiamento'),
  other('OUTRO', 'Outro');

  const FeedbackCategory(this.api, this.label);

  final String api;
  final String label;
}

/// A community report about a district (MAP-04). It stays pending and never changes the map.
@immutable
class RegionFeedback {
  const RegionFeedback(this.category, [this.text = '']);

  static const maxLength = 500;
  static const otherNeedsText = 'Descreva o problema para a categoria Outro.';
  static const tooLong = 'Use até $maxLength caracteres.';

  final FeedbackCategory category;
  final String text;

  /// User-facing validation message, or null when it can be sent.
  String? get error {
    final t = text.trim();
    if (t.length > maxLength) return tooLong;
    if (category == FeedbackCategory.other && t.isEmpty) return otherNeedsText;
    return null;
  }

  Map<String, dynamic> toJson() => {
        'categoria': category.api,
        if (text.trim().isNotEmpty) 'texto': text.trim(),
      };

  @override
  bool operator ==(Object other) => other is RegionFeedback && other.category == category && other.text == text;

  @override
  int get hashCode => Object.hash(category, text);
}
