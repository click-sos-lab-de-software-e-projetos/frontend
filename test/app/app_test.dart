import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alerta_seguro/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // MapScreen asks Geolocator for the position on start; report location off.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (call) async => call.method == 'isLocationServiceEnabled' ? false : null,
    );
  });

  testWidgets('AlertaApp shows the 4 bottom navigation labels', (tester) async {
    await tester.pumpWidget(const AlertaApp());

    for (final label in ['Mapa', 'Emergência', 'Ajustes', 'Perfil']) {
      expect(find.text(label), findsWidgets);
    }
  });
}
