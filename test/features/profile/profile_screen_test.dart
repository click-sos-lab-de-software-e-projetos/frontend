import 'package:alerta_seguro/data/repositories/auth_repository.dart';
import 'package:alerta_seguro/features/auth/login_screen.dart';
import 'package:alerta_seguro/features/auth/register_screen.dart';
import 'package:alerta_seguro/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _profile = Scaffold(body: ProfileScreen());

void main() {
  testWidgets('logged out shows login and sign-up, and hides account data and actions', (tester) async {
    await pumpTestApp(tester, home: _profile);

    expect(find.text('Fazer login'), findsOneWidget);
    expect(find.text('Registrar-se'), findsOneWidget);
    expect(find.text('Privacidade e dados'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Privacidade e dados'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Registrar-se'), findsOneWidget, reason: 'sign-up is secondary');
    expect(
      tester.getTopLeft(find.text('Contatos de confiança')).dy,
      lessThan(tester.getTopLeft(find.text('Fazer login')).dy),
    );
    expect(find.byTooltip('Editar perfil'), findsNothing);
    expect(find.text(FakeAuthRepository.demoProfile.email), findsNothing);
    expect(find.text('Desconectar do Dispositivo'), findsNothing);
  });

  testWidgets('logged out, "Registrar-se" opens the sign-up', (tester) async {
    await pumpTestApp(tester, home: _profile);

    await tester.tap(find.text('Registrar-se'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('logged in shows account data, edit and disconnect, and no login buttons', (tester) async {
    await pumpTestApp(tester, home: _profile, deps: TestDeps(loggedIn: true));

    expect(find.text(FakeAuthRepository.demoProfile.name), findsOneWidget);
    expect(find.byTooltip('Editar perfil'), findsOneWidget);
    expect(find.text(FakeAuthRepository.demoProfile.email), findsOneWidget);
    expect(find.text(FakeAuthRepository.demoProfile.phone), findsOneWidget);
    expect(find.textContaining('ID DE PROTEÇÃO'), findsNothing);
    expect(find.text('DADOS CADASTRAIS'), findsNothing);
    expect(find.text('Fazer login'), findsNothing);
    expect(find.text('Registrar-se'), findsNothing);

    await tester.ensureVisible(find.text('Desconectar do Dispositivo'));
    await tester.tap(find.text('Desconectar do Dispositivo'));
    await tester.pumpAndSettle();

    expect(find.text('Fazer login'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('a consented contact has an X that removes it after warning about consent', (tester) async {
    final deps = await pumpTestApp(tester, home: _profile, deps: TestDeps(loggedIn: true));
    final contact = (await deps.contacts.list()).firstWhere((c) => c.hasConsent);

    expect(find.byIcon(Icons.chat), findsNothing);
    await tester.tap(find.byTooltip('Remover contato'));
    await tester.pumpAndSettle();

    expect(find.text('Remover ${contact.name}?'), findsOneWidget);
    expect(find.text(ProfileScreen.removeWarning(contact)), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text(contact.name), findsOneWidget);

    await tester.tap(find.byTooltip('Remover contato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(find.text(contact.name), findsNothing);
    expect((await deps.contacts.list()).map((c) => c.id), isNot(contains(contact.id)));
  });
}
