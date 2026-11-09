import 'package:alerta_seguro/features/auth/auth_controller.dart';
import 'package:alerta_seguro/features/auth/login_screen.dart';
import 'package:alerta_seguro/features/auth/register_screen.dart';
import 'package:alerta_seguro/features/profile/profile_controller.dart';
import 'package:alerta_seguro/shared/widgets/outline_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

Future<TestDeps> openLogin(WidgetTester tester) async {
  final deps = await pumpTestApp(
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
  return deps;
}

Future<void> tapCreate(WidgetTester tester) async {
  final button = find.widgetWithText(OutlineActionButton, 'Criar conta');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('valid credentials log in, load the profile and close the screen', (tester) async {
    await openLogin(tester);
    await tester.enterText(find.byType(TextField).at(0), 'me@x.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text('Entrar').last);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    final context = tester.element(find.text('abrir'));
    expect(context.read<AuthController>().loggedIn, isTrue);
    expect(context.read<ProfileController>().profile.email, 'me@x.com');
  });

  testWidgets('invalid credentials show the error', (tester) async {
    await openLogin(tester);
    await tester.enterText(find.byType(TextField).at(0), 'me@x.com');
    await tester.tap(find.text('Entrar').last);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
    expect(tester.element(find.byType(LoginScreen)).read<AuthController>().loggedIn, isFalse);
  });

  testWidgets('sign-up validates, creates the account and returns logged in', (tester) async {
    final deps = await openLogin(tester);
    await tester.tap(find.text('Não tem conta? Criar conta'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tapCreate(tester);
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome.'), findsOneWidget);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Informe um telefone válido.'), findsOneWidget);
    expect(find.text('A senha precisa ter ao menos 8 caracteres.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Ana Silva');
    await tester.enterText(find.byType(TextField).at(1), 'ana@x.com');
    await tester.enterText(find.byType(TextField).at(2), '(11) 90000-0000');
    await tester.enterText(find.byType(TextField).at(3), '12345678');
    await tapCreate(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);
    final context = tester.element(find.text('abrir'));
    expect(context.read<AuthController>().loggedIn, isTrue);
    expect(context.read<ProfileController>().profile.phone, '+5511900000000');
    expect(deps.session.isActive, isTrue);
  });

  testWidgets('sign-up with a taken e-mail shows the error', (tester) async {
    final deps = await openLogin(tester);
    await deps.auth.register(name: 'Ana', email: 'ana@x.com', phone: '+5511900000000', password: '12345678');
    await tester.tap(find.text('Não tem conta? Criar conta'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Ana Silva');
    await tester.enterText(find.byType(TextField).at(1), 'ana@x.com');
    await tester.enterText(find.byType(TextField).at(2), '(11) 90000-0000');
    await tester.enterText(find.byType(TextField).at(3), '12345678');
    await tapCreate(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Este e-mail já está cadastrado.'), findsOneWidget);
  });
}
