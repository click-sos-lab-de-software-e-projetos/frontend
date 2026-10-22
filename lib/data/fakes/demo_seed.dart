import '../models/contact.dart';
import '../repositories/auth_repository.dart';

/// Fictitious data shown in demo mode (`USE_FAKE_API=true`). Never put real
/// personal data here.
abstract final class DemoSeed {
  static const profile = FakeAuthRepository.demoProfile;

  static const contacts = [
    Contact(id: 'demo-1', name: 'Contato Exemplo 1', relation: 'Cônjuge', phone: '(11) 90000-0001'),
    Contact(
      id: 'demo-2',
      name: 'Contato Exemplo 2',
      relation: 'Familiar',
      phone: '(11) 90000-0002',
      alertEnabled: false,
    ),
  ];
}
