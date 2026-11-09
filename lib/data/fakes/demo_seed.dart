import '../models/contact.dart';

/// Fictitious contacts shown in demo mode (`USE_FAKE_API=true`) after login.
/// Never put real personal data here.
abstract final class DemoSeed {
  static final contacts = [
    Contact(
      id: 'demo-1',
      name: 'Contato Exemplo 1',
      phone: '+5511900000001',
      consentedAt: DateTime.utc(2026),
    ),
    const Contact(id: 'demo-2', name: 'Contato Exemplo 2', phone: '+5511900000002', alertEnabled: false),
  ];
}
