import 'package:alerta_seguro/features/auth/auth_controller.dart';
import 'package:alerta_seguro/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

Future<void> openLogin(WidgetTester tester) async {
  await pumpTestApp(
    tester,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LoginScreen())),
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('valid credentials log in and close the screen', (tester) async {
    await openLogin(tester);
    await tester.enterText(find.byType(TextField).at(0), 'me@x.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text('Entrar').last);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(tester.element(find.text('abrir')).read<AuthController>().loggedIn, isTrue);
  });

  testWidgets('invalid credentials show "Credenciais inválidas"', (tester) async {
    await openLogin(tester);
    await tester.enterText(find.byType(TextField).at(0), 'me@x.com');
    await tester.tap(find.text('Entrar').last);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Credenciais inválidas.'), findsOneWidget);
    expect(tester.element(find.byType(LoginScreen)).read<AuthController>().loggedIn, isFalse);
  });
}
