import 'package:flutter/foundation.dart';

import '../../core/network/session.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository, this._session) {
    _session.addListener(notifyListeners);
  }

  final AuthRepository _repository;
  final Session _session;

  bool _loading = false;

  bool get loggedIn => _session.isActive;
  bool get loading => _loading;

  /// Logs in and returns the user's profile. Throws the repository's exception
  /// on failure (callers show the message).
  Future<UserProfile> login({required String email, required String password}) =>
      _busy(() => _login(email.trim(), password));

  /// Creates the account and logs in with it.
  Future<UserProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) =>
      _busy(() async {
        await _repository.register(name: name.trim(), email: email.trim(), phone: phone, password: password);
        return _login(email.trim(), password);
      });

  void logout() => _session.clear();

  /// Deletes the account and ends the session (the saved token is erased).
  /// On failure the session is kept and the exception rethrown.
  Future<void> deleteAccount(String password) => _busy(() async {
        await _repository.deleteAccount(password);
        _session.clear();
      });

  Future<UserProfile> _login(String email, String password) async {
    _session.start(await _repository.login(email: email, password: password));
    try {
      return await _repository.me();
    } catch (_) {
      _session.clear();
      rethrow;
    }
  }

  Future<T> _busy<T>(Future<T> Function() action) async {
    _loading = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _session.removeListener(notifyListeners);
    super.dispose();
  }
}
