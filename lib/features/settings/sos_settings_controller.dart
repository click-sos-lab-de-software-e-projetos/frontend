import 'package:flutter/foundation.dart';

import '../../data/models/sos_settings.dart';

class SosSettingsController extends ChangeNotifier {
  SosSettingsController([this._settings = const SosSettings()]);

  SosSettings _settings;

  SosSettings get settings => _settings;

  void setSilentAlert(bool value) => _set(_settings.copyWith(silentAlert: value));

  void _set(SosSettings s) {
    if (s == _settings) return;
    _settings = s;
    notifyListeners();
  }
}
