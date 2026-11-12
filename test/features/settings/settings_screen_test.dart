import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/features/contacts/add_contact_screen.dart';
import 'package:alerta_seguro/features/contacts/contacts_controller.dart';
import 'package:alerta_seguro/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('toggles contacts', (tester) async {
    await pumpTestApp(tester, home: const Scaffold(body: SettingsScreen()), deps: TestDeps(loggedIn: true));
    final context = tester.element(find.byType(SettingsScreen));

    expect(context.read<ContactsController>().activeContacts.map((c) => c.id), ['demo-1']);
    expect(find.text('Aguardando consentimento do contato'), findsOneWidget);
    await tester.tap(find.text('Contato Exemplo 2'));
    await tester.pumpAndSettle();
    expect(context.read<ContactsController>().activeContacts.map((c) => c.id), ['demo-1', 'demo-2']);
  });

  testWidgets('saves the SOS message on the account and clears it back to the default', (tester) async {
    final deps =
        await pumpTestApp(tester, home: const Scaffold(body: SettingsScreen()), deps: TestDeps(loggedIn: true));
    expect(find.text(SettingsScreen.defaultMessageLabel), findsOneWidget);

    await tester.tap(find.text('ALTERAR'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Me ajude!');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('"Me ajude!"'), findsOneWidget);
    expect((await deps.auth.me()).sosMessage, 'Me ajude!');

    await tester.tap(find.text('ALTERAR'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text(SettingsScreen.defaultMessageLabel), findsOneWidget);
    expect((await deps.auth.me()).sosMessage, '');
  });

  testWidgets('shows the server error when the active limit is reached', (tester) async {
    await pumpTestApp(
      tester,
      home: const Scaffold(body: SettingsScreen()),
      deps: TestDeps(
        loggedIn: true,
        contacts: const [
          Contact(id: '1', name: 'Um', phone: '+5511900000001'),
          Contact(id: '2', name: 'Dois', phone: '+5511900000002'),
          Contact(id: '3', name: 'Três', phone: '+5511900000003'),
          Contact(id: '4', name: 'Quatro', phone: '+5511900000004', alertEnabled: false),
        ],
      ),
    );

    await tester.tap(find.text('Quatro'));
    await tester.pumpAndSettle();

    expect(find.text('Limite de 3 contatos ativos atingido.'), findsOneWidget);
  });

  testWidgets('"+ ADICIONAR" opens the new contact form', (tester) async {
    await pumpTestApp(tester, home: const Scaffold(body: SettingsScreen()), deps: TestDeps(loggedIn: true));

    await tester.tap(find.text('+ ADICIONAR'));
    await tester.pumpAndSettle();

    expect(find.byType(AddContactScreen), findsOneWidget);
  });

  testWidgets('asks to log in when logged out', (tester) async {
    await pumpTestApp(tester, home: const Scaffold(body: SettingsScreen()));
    expect(find.textContaining('Entre na sua conta'), findsOneWidget);
    expect(find.text('Contato Exemplo 1'), findsNothing);
    expect(find.text('ALTERAR'), findsNothing);
    expect(find.text('+ ADICIONAR'), findsNothing);
  });
}
