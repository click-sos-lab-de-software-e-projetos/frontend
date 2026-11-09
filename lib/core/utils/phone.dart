import '../services/whatsapp_service.dart';

final _e164 = RegExp(r'^\+[1-9][0-9]{7,14}$');

/// Converts a typed phone (e.g. `(11) 90000-0001`) to E.164 (`+5511900000001`),
/// the format the backend requires. Brazilian numbers without `+55` get it.
String toE164(String phone) => '+${WhatsAppService.normalizePhone(phone)}';

bool isValidPhone(String phone) => phone.trim().isNotEmpty && _e164.hasMatch(toE164(phone));
