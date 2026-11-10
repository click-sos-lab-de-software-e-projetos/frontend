import 'package:flutter/foundation.dart';

import 'token_store.dart';

/// Holds the JWT of the logged-in user and keeps a copy in [TokenStore], so the
/// session survives app restarts.
class Session extends ChangeNotifier {
  Session({TokenStore? store}) : _store = store ?? MemoryTokenStore();

  final TokenStore _store;
  String? _token;

  String? get token => _token;
  bool get isActive => _token != null;

  /// Starts the session with the saved token, if any. Call before the app runs.
  Future<void> restore() async {
    final saved = await _store.read();
    if (saved != null && saved.isNotEmpty) _set(saved);
  }

  void start(String token) {
    if (token == _token) return;
    _set(token);
    _store.write(token);
  }

  void clear() {
    if (_token == null) return;
    _set(null);
    _store.delete();
  }

  void _set(String? token) {
    _token = token;
    notifyListeners();
  }
}
