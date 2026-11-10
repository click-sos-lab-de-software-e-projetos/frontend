import 'package:flutter/foundation.dart';

import '../../core/network/session.dart';
import '../../core/services/geo_point.dart';
import '../../core/services/location_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../data/models/contact.dart';
import '../../data/models/sos_alert.dart';
import '../../data/repositories/alert_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../contacts/contacts_controller.dart';
import '../profile/profile_controller.dart';

enum SosPhase { idle, countdown, sending, pending, sent, failed, stillSending, error }

@immutable
class SosState {
  const SosState(this.phase, {this.secondsLeft = 0, this.attempts = 0, this.error});

  static const idle = SosState(SosPhase.idle);

  final SosPhase phase;
  final int secondsLeft;
  final int attempts;

  /// User-facing message when [phase] is [SosPhase.error].
  final String? error;
}

/// One tap starts a cancellable countdown; then the alert goes to the server,
/// which sends it by WhatsApp, and its delivery is followed until final (Regra 04).
class SosController extends ChangeNotifier {
  SosController({
    required AlertRepository alerts,
    required LocationService location,
    required ContactsController contacts,
    required ProfileController profile,
    required Session session,
    this.countdownSeconds = 5,
    Duration tick = const Duration(seconds: 1),
    Duration pollEvery = const Duration(seconds: 3),
    int maxPolls = 40, // 2 min with a poll every 3 s
  })  : _alerts = alerts,
        _location = location,
        _contacts = contacts,
        _profile = profile,
        _session = session,
        _tick = tick,
        _pollEvery = pollEvery,
        _maxPolls = maxPolls;

  static const notLoggedIn = 'Entre na sua conta (aba Perfil) para enviar o alerta.';
  static const noLocation = 'Localização indisponível: o alerta não foi enviado ao servidor.';
  static const whatsAppDefault = '[Alerta Seguro] Preciso de ajuda urgente!';

  final int countdownSeconds;
  final AlertRepository _alerts;
  final LocationService _location;
  final ContactsController _contacts;
  final ProfileController _profile;
  final Session _session;
  final Duration _tick;
  final Duration _pollEvery;
  final int _maxPolls;

  SosState _state = SosState.idle;
  GeoPoint? _position;

  /// Bumped to abandon the running flow (cancel, dismiss, dispose).
  int _run = 0;
  bool _disposed = false;

  SosState get state => _state;
  bool get busy => const {SosPhase.countdown, SosPhase.sending, SosPhase.pending}.contains(_state.phase);
  List<Contact> get targets => _contacts.activeContacts;

  /// Text for the WhatsApp fallback: the message saved in Ajustes (or a default) and the map link.
  String whatsAppText({bool withLocation = true}) {
    final saved = _profile.profile.sosMessage.trim();
    final position = withLocation ? _position : null;
    final link = position == null ? '(localização indisponível)' : WhatsAppService.mapsLink(position);
    return '${saved.isEmpty ? whatsAppDefault : saved} $link';
  }

  Future<void> start() async {
    if (busy) return;
    final run = ++_run;
    _position = null;
    if (!_session.isActive) return _set(const SosState(SosPhase.error, error: notLoggedIn));

    for (var s = countdownSeconds; s > 0; s--) {
      _set(SosState(SosPhase.countdown, secondsLeft: s));
      await Future<void>.delayed(_tick);
      if (run != _run) return;
    }

    _set(const SosState(SosPhase.sending));
    final position = await _location.currentPosition();
    if (run != _run) return;
    if (position == null) return _set(const SosState(SosPhase.error, error: noLocation));
    _position = position;

    final String id;
    try {
      // No message: the server uses the one saved in Ajustes, or the Regra 02 default.
      id = await _alerts.send(SosAlert(latitude: position.lat, longitude: position.lng));
    } on RepositoryException catch (e) {
      if (run == _run) _set(SosState(SosPhase.error, error: e.message));
      return;
    }
    if (run != _run) return;
    _set(const SosState(SosPhase.pending));

    for (var i = 0; i < _maxPolls; i++) {
      await Future<void>.delayed(_pollEvery);
      if (run != _run) return;
      final AlertStatus status;
      try {
        status = await _alerts.status(id);
      } on UnauthorizedException catch (e) {
        if (run == _run) _set(SosState(SosPhase.error, error: e.message));
        return;
      } on RepositoryException {
        continue; // offline for a moment: keep trying until the time limit
      }
      if (run != _run) return;
      if (status.delivery.isFinal) {
        final phase = status.delivery == AlertDelivery.sent ? SosPhase.sent : SosPhase.failed;
        return _set(SosState(phase, attempts: status.attempts));
      }
      _set(SosState(SosPhase.pending, attempts: status.attempts));
    }
    _set(const SosState(SosPhase.stillSending));
  }

  /// Stops the countdown; once the alert is on the server it cannot be cancelled.
  void cancel() {
    if (_state.phase != SosPhase.countdown) return;
    _run++;
    _set(SosState.idle);
  }

  /// Hides the result of the last alert.
  void dismiss() {
    if (busy) return;
    _run++;
    _set(SosState.idle);
  }

  void _set(SosState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _run++;
    _disposed = true;
    super.dispose();
  }
}
