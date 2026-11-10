import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/network/session.dart';
import '../../data/models/contact.dart';
import '../../data/repositories/contact_repository.dart';
import '../../data/repositories/repository_exception.dart';

/// The logged-in user's trusted contacts, kept in sync with the server.
/// Loads on login and clears on logout.
class ContactsController extends ChangeNotifier {
  ContactsController(this._repository, this._session) {
    _session.addListener(_onSession);
    if (_session.isActive) unawaited(load());
  }

  final ContactRepository _repository;
  final Session _session;

  List<Contact> _contacts = const [];
  bool _loading = false;
  String? _error;
  AppLifecycleListener? _resumeListener;

  List<Contact> get contacts => List.unmodifiable(_contacts);
  List<Contact> get activeContacts => _contacts.where((c) => c.alertEnabled).toList(growable: false);
  bool get loading => _loading;

  /// Message of the last failed [load], if any.
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final loaded = await _repository.list();
      if (_session.isActive) _contacts = loaded;
    } on RepositoryException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// [phone] must be E.164. Throws [RepositoryException] on failure.
  Future<Contact> add({required String name, required String phone}) async {
    if (name.trim().isEmpty || phone.trim().isEmpty) throw ArgumentError('name and phone are required');
    final contact = await _repository.create(name: name.trim(), phone: phone.trim());
    _contacts = [..._contacts, contact];
    notifyListeners();
    return contact;
  }

  /// Throws [RepositoryException] on failure (e.g. active-contact limit).
  Future<void> setAlertEnabled(String id, bool enabled) async {
    final i = _contacts.indexWhere((c) => c.id == id);
    if (i < 0 || _contacts[i].alertEnabled == enabled) return;
    _replace(await _repository.update(id, alertEnabled: enabled));
  }

  /// Sends only what differs ([phone] in E.164); no change, no request.
  /// A new phone makes the server ask for consent again.
  /// Throws [RepositoryException] on failure.
  Future<void> edit(String id, {required String name, required String phone}) async {
    final current = _contacts.firstWhere((c) => c.id == id);
    final newName = name.trim();
    final newPhone = phone.trim();
    if (newName.isEmpty || newPhone.isEmpty) throw ArgumentError('name and phone are required');
    final changedName = newName == current.name ? null : newName;
    final changedPhone = newPhone == current.phone ? null : newPhone;
    if (changedName == null && changedPhone == null) return;
    _replace(await _repository.update(id, name: changedName, phone: changedPhone));
  }

  Future<void> remove(String id) async {
    await _repository.delete(id);
    _contacts = _contacts.where((c) => c.id != id).toList(growable: false);
    notifyListeners();
  }

  /// WhatsApp text inviting the contact to accept or refuse alerts. After the
  /// first invite, contacts reload whenever the app resumes, so the status
  /// changes when the user comes back from WhatsApp.
  /// Throws [RepositoryException] on failure.
  Future<String> consentInvite(String id) async {
    final contact = _contacts.firstWhere((c) => c.id == id);
    final link = await _repository.requestConsentLink(id);
    _resumeListener ??= AppLifecycleListener(onResume: () => unawaited(load()));
    return 'Oi, ${contact.name}! Quero cadastrar você como meu contato de emergência no Click S.O.S. '
        'Para aceitar ou recusar, abra o link: $link';
  }

  void _replace(Contact updated) {
    _contacts = [for (final c in _contacts) c.id == updated.id ? updated : c];
    notifyListeners();
  }

  void _onSession() {
    if (_session.isActive) {
      unawaited(load());
    } else {
      _contacts = const [];
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _resumeListener?.dispose();
    super.dispose();
  }
}
