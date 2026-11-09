import 'package:flutter/foundation.dart';

/// Holds the JWT of the logged-in user, in memory only (lost when the app closes).
class Session extends ChangeNotifier {
  String? _token;

  String? get token => _token;
  bool get isActive => _token != null;

  void start(String token) {
    if (token == _token) return;
    _token = token;
    notifyListeners();
  }

  void clear() {
    if (_token == null) return;
    _token = null;
    notifyListeners();
  }
}
