import 'package:alerta_seguro/features/auth/auth_controller.dart';
import 'package:alerta_seguro/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('logged out: no contacts and a login prompt', (tester) async {
    await pumpTestApp(tester, home: const Scaffold(body: ProfileScreen()));

    expect(find.text('CONTATOS DE CONFIANÇA (0)'), findsOneWidget);
    expect(find.text('+ ADICIONAR'), findsNothing);
    expect(find.text('Fazer Login'), findsOneWidget);
  });

  testWidgets('adding a contact validates, converts the phone to E.164 and lists it', (tester) async {
    final deps = await pumpTestApp(
      tester,
      home: const Scaffold(body: ProfileScreen()),
      deps: TestDeps(contacts: const [], loggedIn: true),
    );
    expect(find.text('CONTATOS DE CONFIANÇA (0)'), findsOneWidget);

    await tester.tap(find.text('+ ADICIONAR'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome.'), findsOneWidget);
    expect(find.text('Informe o telefone.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Bia');
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.text('Telefone inválido.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '(11) 90000-1234');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('CONTATOS DE CONFIANÇA (1)'), findsOneWidget);
    expect(find.text('Bia'), findsOneWidget);
    expect(find.text('+5511900001234 · Aguardando consentimento'), findsOneWidget);
    expect((await deps.contacts.list()).single.phone, '+5511900001234');
  });

  testWidgets('logging out clears the contacts', (tester) async {
    await pumpTestApp(tester, home: const Scaffold(body: ProfileScreen()), deps: TestDeps(loggedIn: true));
    expect(find.text('Contato Exemplo 1'), findsOneWidget);

    tester.element(find.byType(ProfileScreen)).read<AuthController>().logout();
    await tester.pumpAndSettle();
    expect(find.text('Contato Exemplo 1'), findsNothing);
    expect(find.text('CONTATOS DE CONFIANÇA (0)'), findsOneWidget);
  });
}
