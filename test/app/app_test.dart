import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('AlertaApp shows the 4 bottom navigation labels', (tester) async {
    await pumpTestApp(tester);

    for (final label in ['Mapa', 'Emergência', 'Ajustes', 'Perfil']) {
      expect(find.text(label), findsWidgets);
    }
  });
}
