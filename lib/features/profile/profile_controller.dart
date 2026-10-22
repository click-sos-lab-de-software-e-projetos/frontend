import 'package:flutter/foundation.dart';

import '../../data/models/user_profile.dart';

class ProfileController extends ChangeNotifier {
  ProfileController([this._profile = UserProfile.empty]);

  UserProfile _profile;

  UserProfile get profile => _profile;

  void replace(UserProfile profile) {
    if (profile == _profile) return;
    _profile = profile;
    notifyListeners();
  }

  void update({String? name, String? email, String? phone}) =>
      replace(_profile.copyWith(name: name?.trim(), email: email?.trim(), phone: phone?.trim()));
}
