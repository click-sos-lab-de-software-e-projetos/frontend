import 'package:flutter/foundation.dart';

import '../../core/network/session.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repository_exception.dart';

class ProfileController extends ChangeNotifier {
  /// With a [session], the profile is reset when the session ends.
  ProfileController([this._profile = UserProfile.empty, this._session]) {
    _session?.addListener(_onSession);
  }

  UserProfile _profile;
  final Session? _session;

  UserProfile get profile => _profile;

  void replace(UserProfile profile) {
    if (profile == _profile) return;
    _profile = profile;
    notifyListeners();
  }

  /// Fetches the profile of a session restored at startup. A rejected token
  /// ends the session; other failures keep it (e.g. offline or server waking up).
  Future<void> load(AuthRepository auth) async {
    final session = _session;
    final token = session?.token;
    if (session == null || token == null) return;
    try {
      final profile = await auth.me();
      if (session.token == token) replace(profile);
    } on UnauthorizedException {
      if (session.token == token) session.clear();
    } on RepositoryException {
      // Keep the saved session.
    }
  }

  /// Saves the SOS message on the account; empty goes back to the default text.
  Future<void> saveSosMessage(AuthRepository auth, String message) async =>
      replace(await auth.updateSosMessage(message.trim()));

  void update({String? name, String? email, String? phone}) =>
      replace(_profile.copyWith(name: name?.trim(), email: email?.trim(), phone: phone?.trim()));

  void _onSession() {
    if (!_session!.isActive) replace(UserProfile.empty);
  }

  @override
  void dispose() {
    _session?.removeListener(_onSession);
    super.dispose();
  }
}
