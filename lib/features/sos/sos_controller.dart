import '../../core/services/location_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../data/models/contact.dart';
import '../../data/models/sos_alert.dart';
import '../../data/repositories/alert_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../contacts/contacts_controller.dart';
import '../profile/profile_controller.dart';
import '../settings/sos_settings_controller.dart';

class SosOutcome {
  const SosOutcome({required this.message, required this.targets, this.alertError});

  final String message;
  final List<Contact> targets;

  /// Set when the alert could not be sent to the server (WhatsApp still works).
  final String? alertError;
}

class SosController {
  SosController({
    required AlertRepository alerts,
    required LocationService location,
    required ContactsController contacts,
    required SosSettingsController settings,
    required ProfileController profile,
  })  : _alerts = alerts,
        _location = location,
        _contacts = contacts,
        _settings = settings,
        _profile = profile;

  final AlertRepository _alerts;
  final LocationService _location;
  final ContactsController _contacts;
  final SosSettingsController _settings;
  final ProfileController _profile;

  Future<SosOutcome> trigger() async {
    final pos = await _location.currentPosition();
    final link = pos != null ? WhatsAppService.mapsLink(pos) : '(localização indisponível)';
    final message = '${_settings.settings.message} $link';
    String? error;
    try {
      await _alerts.send(
        SosAlert(
          lat: pos?.lat,
          lng: pos?.lng,
          message: message,
          userId: _profile.profile.protectionId,
        ),
      );
    } on RepositoryException catch (e) {
      error = e.message;
    }
    return SosOutcome(message: message, targets: _contacts.activeContacts, alertError: error);
  }
}
