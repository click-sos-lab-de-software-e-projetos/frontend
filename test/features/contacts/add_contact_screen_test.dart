import 'package:alerta_seguro/features/auth/auth_controller.dart';
import 'package:alerta_seguro/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('adding a contact validates fields and shows it in the profile', (tester) async {
    await pumpTestApp(tester, home: const Scaffold(body: ProfileScreen()), deps: TestDeps(contacts: const []));
    expect(find.text('CONTATOS DE CONFIANÇA (0)'), findsOneWidget);

    await tester.tap(find.text('+ ADICIONAR'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome.'), findsOneWidget);
    expect(find.text('Informe o telefone.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Bia');
    await tester.enterText(find.byType(TextField).at(1), '(11) 90000-1234');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('CONTATOS DE CONFIANÇA (1)'), findsOneWidget);
    // Contacts are listed only after login.
    expect(find.text('Bia'), findsNothing);
    await tester.element(find.byType(ProfileScreen)).read<AuthController>().login(email: 'a@x', password: '1');
    await tester.pumpAndSettle();
    expect(find.text('Bia'), findsOneWidget);
    expect(find.text('B'), findsOneWidget); // avatar initial
  });
}
