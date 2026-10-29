import 'package:alerta_seguro/features/sos/widgets/sos_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fires only after being held for the whole duration', (tester) async {
    var fired = 0;
    await tester.pumpWidget(MaterialApp(home: Center(child: SosButton(onTriggered: () => fired++))));

    final gesture = await tester.startGesture(tester.getCenter(find.text('SOS')));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(fired, 0);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    expect(fired, 1);
  });
}
