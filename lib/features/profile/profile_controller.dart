import 'package:flutter/foundation.dart';

import '../../core/network/session.dart';
import '../../data/models/user_profile.dart';

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
