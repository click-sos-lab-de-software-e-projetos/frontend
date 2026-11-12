import 'package:click_sos/data/models/sos_settings.dart';
import 'package:click_sos/features/settings/sos_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults', () {
    expect(SosSettingsController().settings, const SosSettings());
  });

  test('setSilentAlert notifies only on change', () {
    final c = SosSettingsController();
    var notified = 0;
    c.addListener(() => notified++);
    c.setSilentAlert(true);
    c.setSilentAlert(false);
    expect(c.settings.silentAlert, isFalse);
    expect(notified, 1);
  });
}
