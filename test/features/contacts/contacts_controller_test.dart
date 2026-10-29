import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/features/contacts/contacts_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var n = 0;
  ContactsController build([List<Contact> initial = const []]) =>
      ContactsController(initial: initial, newId: () => 'id${n++}');

  setUp(() => n = 0);

  test('add trims fields, defaults relation and notifies', () {
    final c = build();
    var notified = false;
    c.addListener(() => notified = true);

    final added = c.add(name: ' Ana ', phone: ' 11 9 ', relation: ' ');

    expect(added, const Contact(id: 'id0', name: 'Ana', phone: '11 9', relation: 'Contato'));
    expect(c.contacts, [added]);
    expect(notified, isTrue);
  });

  test('add rejects empty name or phone', () {
    final c = build();
    expect(() => c.add(name: ' ', phone: '1'), throwsArgumentError);
    expect(() => c.add(name: 'A', phone: ''), throwsArgumentError);
    expect(c.contacts, isEmpty);
  });

  test('setAlertEnabled toggles one contact and activeContacts follows', () {
    final c = build(const [
      Contact(id: 'a', name: 'A', relation: 'r', phone: '1'),
      Contact(id: 'b', name: 'B', relation: 'r', phone: '2', alertEnabled: false),
    ]);
    expect(c.activeContacts.map((e) => e.id), ['a']);

    c.setAlertEnabled('b', true);
    c.setAlertEnabled('a', false);
    expect(c.activeContacts.map((e) => e.id), ['b']);
  });

  test('contacts list is unmodifiable', () {
    expect(
      () => build().contacts.add(const Contact(id: 'x', name: 'x', relation: 'x', phone: 'x')),
      throwsUnsupportedError,
    );
  });
}
