import 'package:flutter/foundation.dart';

import '../../data/models/contact.dart';

class ContactsController extends ChangeNotifier {
  ContactsController({List<Contact> initial = const [], String Function()? newId})
      : _contacts = [...initial],
        _newId = newId ?? _defaultId;

  static int _seq = 0;
  static String _defaultId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  final List<Contact> _contacts;
  final String Function() _newId;

  List<Contact> get contacts => List.unmodifiable(_contacts);
  List<Contact> get activeContacts => _contacts.where((c) => c.alertEnabled).toList(growable: false);

  Contact add({required String name, required String phone, String relation = ''}) {
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      throw ArgumentError('name and phone are required');
    }
    final contact = Contact(
      id: _newId(),
      name: name.trim(),
      phone: phone.trim(),
      relation: relation.trim().isEmpty ? 'Contato' : relation.trim(),
    );
    _contacts.add(contact);
    notifyListeners();
    return contact;
  }

  void setAlertEnabled(String id, bool enabled) {
    final i = _contacts.indexWhere((c) => c.id == id);
    if (i < 0 || _contacts[i].alertEnabled == enabled) return;
    _contacts[i] = _contacts[i].copyWith(alertEnabled: enabled);
    notifyListeners();
  }
}
