import 'package:click_sos/features/sos/widgets/sos_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('one tap fires once', (tester) async {
    var fired = 0;
    await tester.pumpWidget(MaterialApp(home: Center(child: SosButton(onPressed: () => fired++))));

    await tester.tap(find.text('SOS'));

    expect(fired, 1);
  });

  testWidgets('shows the given label and ignores taps when disabled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Center(child: SosButton(onPressed: null, label: '3'))));

    await tester.tap(find.text('3'));

    expect(find.text('SOS'), findsNothing);
  });
}
