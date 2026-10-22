import 'package:alerta_seguro/data/models/user_profile.dart';
import 'package:alerta_seguro/features/profile/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts empty and updates trimmed fields', () {
    final c = ProfileController();
    expect(c.profile, UserProfile.empty);

    var notified = 0;
    c.addListener(() => notified++);
    c.update(name: ' Ana ', email: 'a@x');
    expect(c.profile, const UserProfile(name: 'Ana', email: 'a@x', phone: '', protectionId: ''));

    c.update(name: 'Ana'); // no change → no notification
    expect(notified, 1);
  });

  test('replace swaps the whole profile', () {
    final c = ProfileController();
    const p = UserProfile(name: 'N', email: 'e', phone: 'p', protectionId: '#1');
    c.replace(p);
    expect(c.profile, p);
  });
}
