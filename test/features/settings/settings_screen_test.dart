import 'package:alerta_seguro/features/contacts/contacts_controller.dart';
import 'package:alerta_seguro/features/settings/settings_screen.dart';
import 'package:alerta_seguro/features/settings/sos_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('toggles contacts and edits the SOS message', (tester) async {
    await pumpTestApp(tester, home: const Scaffold(body: SettingsScreen()));
    final context = tester.element(find.byType(SettingsScreen));

    expect(context.read<ContactsController>().activeContacts.map((c) => c.id), ['demo-1']);
    await tester.tap(find.text('Contato Exemplo 2'));
    await tester.pump();
    expect(context.read<ContactsController>().activeContacts.map((c) => c.id), ['demo-1', 'demo-2']);

    await tester.tap(find.text('ALTERAR'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Me ajude!');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(context.read<SosSettingsController>().settings.message, 'Me ajude!');
    expect(find.text('"Me ajude! [link do mapa]"'), findsOneWidget);
  });
}
