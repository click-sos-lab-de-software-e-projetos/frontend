import 'package:flutter/foundation.dart';

import '../../data/models/sos_settings.dart';

class SosSettingsController extends ChangeNotifier {
  SosSettingsController([this._settings = const SosSettings()]);

  SosSettings _settings;

  SosSettings get settings => _settings;

  void setMessage(String message) {
    final m = message.trim();
    if (m.isEmpty) throw ArgumentError('message must not be empty');
    if (m.length > SosSettings.maxMessageLength) {
      throw ArgumentError('message must have at most ${SosSettings.maxMessageLength} characters');
    }
    _set(_settings.copyWith(message: m));
  }

  void setSilentAlert(bool value) => _set(_settings.copyWith(silentAlert: value));

  void _set(SosSettings s) {
    if (s == _settings) return;
    _settings = s;
    notifyListeners();
  }
}
