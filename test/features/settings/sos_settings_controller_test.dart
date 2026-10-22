import 'package:alerta_seguro/data/models/sos_settings.dart';
import 'package:alerta_seguro/features/settings/sos_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults', () {
    expect(SosSettingsController().settings, const SosSettings());
  });

  test('setMessage trims and validates length', () {
    final c = SosSettingsController();
    c.setMessage('  socorro  ');
    expect(c.settings.message, 'socorro');

    expect(() => c.setMessage('   '), throwsArgumentError);
    expect(() => c.setMessage('x' * 161), throwsArgumentError);
    expect(c.settings.message, 'socorro');
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
