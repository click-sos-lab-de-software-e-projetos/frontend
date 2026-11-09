import '../../core/network/session.dart';
import '../../core/services/location_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../data/models/contact.dart';
import '../../data/models/sos_alert.dart';
import '../../data/repositories/alert_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../contacts/contacts_controller.dart';
import '../settings/sos_settings_controller.dart';

class SosOutcome {
  const SosOutcome({required this.message, required this.targets, this.alertError});

  final String message;
  final List<Contact> targets;

  /// Set when the alert could not be registered on the server (WhatsApp still works).
  final String? alertError;
}

class SosController {
  SosController({
    required AlertRepository alerts,
    required LocationService location,
    required ContactsController contacts,
    required SosSettingsController settings,
    required Session session,
  })  : _alerts = alerts,
        _location = location,
        _contacts = contacts,
        _settings = settings,
        _session = session;

  static const notLoggedIn = 'Entre na sua conta para registrar o alerta no servidor.';
  static const noLocation = 'Localização indisponível: o alerta não foi registrado no servidor.';

  final AlertRepository _alerts;
  final LocationService _location;
  final ContactsController _contacts;
  final SosSettingsController _settings;
  final Session _session;

  Future<SosOutcome> trigger() async {
    final pos = await _location.currentPosition();
    final link = pos != null ? WhatsAppService.mapsLink(pos) : '(localização indisponível)';
    final text = _settings.settings.message;
    String? error;
    if (!_session.isActive) {
      error = notLoggedIn;
    } else if (pos == null) {
      error = noLocation;
    } else {
      try {
        await _alerts.send(SosAlert(latitude: pos.lat, longitude: pos.lng, message: text));
      } on RepositoryException catch (e) {
        error = e.message;
      }
    }
    return SosOutcome(message: '$text $link', targets: _contacts.activeContacts, alertError: error);
  }
}
