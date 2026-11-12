import 'package:click_sos/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('AlertaApp shows the 4 bottom navigation labels', (tester) async {
    await pumpTestApp(tester);

    for (final label in ['Mapa', 'Emergência', 'Ajustes', 'Perfil']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('a restored session loads the profile on startup', (tester) async {
    await pumpTestApp(tester, deps: TestDeps(loggedIn: true));

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text(FakeAuthRepository.demoProfile.name), findsOneWidget);
  });
}
