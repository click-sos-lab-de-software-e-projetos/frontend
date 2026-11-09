import 'package:alerta_seguro/core/network/session.dart';
import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/repositories/contact_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/contacts/contacts_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingList extends FakeContactRepository {
  @override
  Future<List<Contact>> list() => Future.error(const RepositoryException('offline'));
}

void main() {
  const a = Contact(id: 'a', name: 'A', phone: '+1');
  const b = Contact(id: 'b', name: 'B', phone: '+2', alertEnabled: false);

  test('loads on login and clears on logout', () async {
    final session = Session();
    final c = ContactsController(FakeContactRepository(const [a, b]), session);
    expect(c.contacts, isEmpty);

    session.start('t');
    await pumpEventQueue();
    expect(c.contacts, [a, b]);
    expect(c.activeContacts, [a]);

    session.clear();
    expect(c.contacts, isEmpty);
  });

  test('loads immediately when the session is already active', () async {
    final c = ContactsController(FakeContactRepository(const [a]), Session()..start('t'));
    await pumpEventQueue();
    expect(c.contacts, [a]);
  });

  test('load failure is exposed as error', () async {
    final c = ContactsController(_FailingList(), Session()..start('t'));
    await pumpEventQueue();
    expect(c.error, 'offline');
    expect(c.loading, isFalse);
  });

  test('add trims, saves on the server and notifies', () async {
    final repo = FakeContactRepository();
    final c = ContactsController(repo, Session()..start('t'));
    await pumpEventQueue();
    var notified = false;
    c.addListener(() => notified = true);

    final added = await c.add(name: ' Ana ', phone: ' +5511900000001 ');

    expect(added.name, 'Ana');
    expect(added.phone, '+5511900000001');
    expect(c.contacts, [added]);
    expect(await repo.list(), [added]);
    expect(notified, isTrue);
  });

  test('add rejects empty name or phone', () async {
    final c = ContactsController(FakeContactRepository(), Session()..start('t'));
    expect(() => c.add(name: ' ', phone: '+1'), throwsArgumentError);
    expect(() => c.add(name: 'A', phone: ''), throwsArgumentError);
  });

  test('setAlertEnabled updates on the server and surfaces the limit error', () async {
    final c = ContactsController(
      FakeContactRepository(const [
        a,
        Contact(id: 'c', name: 'C', phone: '+3'),
        Contact(id: 'd', name: 'D', phone: '+4'),
        b,
      ]),
      Session()..start('t'),
    );
    await pumpEventQueue();

    await expectLater(c.setAlertEnabled('b', true), throwsA(isA<RepositoryException>()));
    await c.setAlertEnabled('a', false);
    await c.setAlertEnabled('b', true);
    expect(c.activeContacts.map((e) => e.id), ['c', 'd', 'b']);
  });

  test('remove deletes the contact', () async {
    final c = ContactsController(FakeContactRepository(const [a, b]), Session()..start('t'));
    await pumpEventQueue();
    await c.remove('a');
    expect(c.contacts, [b]);
  });

  test('consentInvite builds the WhatsApp text with the link', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final c = ContactsController(FakeContactRepository(const [a]), Session()..start('t'));
    await pumpEventQueue();

    final text = await c.consentInvite('a');

    expect(text, startsWith('Oi, A! Quero cadastrar você como meu contato de emergência no Click S.O.S.'));
    expect(text, endsWith('#token=fake-a'));
    c.dispose();
  });
}
