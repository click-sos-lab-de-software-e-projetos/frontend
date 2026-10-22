import 'package:flutter/foundation.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  bool _loggedIn = false;
  bool _loading = false;

  bool get loggedIn => _loggedIn;
  bool get loading => _loading;

  /// Throws the repository's exception on failure (callers show the message).
  Future<UserProfile> login({required String email, required String password}) async {
    _loading = true;
    notifyListeners();
    try {
      final profile = await _repository.login(email: email, password: password);
      _loggedIn = true;
      return profile;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void logout() {
    if (!_loggedIn) return;
    _loggedIn = false;
    notifyListeners();
  }
}
