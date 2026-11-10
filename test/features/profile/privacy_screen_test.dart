import 'package:alerta_seguro/data/repositories/auth_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/auth/auth_controller.dart';
import 'package:alerta_seguro/features/auth/login_screen.dart';
import 'package:alerta_seguro/features/profile/privacy_screen.dart';
import 'package:alerta_seguro/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

class _Auth extends FakeAuthRepository {
  int deletes = 0;

  @override
  Future<void> deleteAccount(String password) async {
    deletes++;
    if (password != 'certa') throw const RepositoryException('Senha incorreta.');
    return super.deleteAccount(password);
  }
}

Future<void> _openPrivacy(WidgetTester tester) async {
  final button = find.text('Privacidade e dados');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  const profile = Scaffold(body: ProfileScreen());

  testWidgets('logged out, the profile opens the policy without account deletion', (tester) async {
    await pumpTestApp(tester, home: profile);
    await _openPrivacy(tester);

    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.text(PrivacyScreen.retention), findsOneWidget);
    expect(find.text(PrivacyScreen.deletion), findsOneWidget);
    expect(find.text('Excluir conta'), findsNothing);
  });

  group('deleting the account', () {
    late _Auth auth;

    Future<void> start(WidgetTester tester) async {
      auth = _Auth();
      await pumpTestApp(tester, home: profile, deps: TestDeps(loggedIn: true, auth: auth));
      await _openPrivacy(tester);
      await _tapVisible(tester, 'Excluir conta');
    }

    testWidgets('cancelling the first confirmation does nothing', (tester) async {
      await start(tester);

      expect(find.text(PrivacyScreen.deleteWarning), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyScreen), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(auth.deletes, 0);
    });

    testWidgets('a wrong password keeps the account and explains', (tester) async {
      await start(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'errada');
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Senha incorreta.'), findsOneWidget);
      expect(tester.element(find.byType(PrivacyScreen)).read<AuthController>().loggedIn, isTrue);
    });

    testWidgets('the right password deletes, logs out and opens the login', (tester) async {
      await start(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'certa');
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(auth.deletes, 1);
      expect(find.byType(PrivacyScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(PrivacyScreen.deleted), findsOneWidget);
      expect(tester.element(find.byType(LoginScreen)).read<AuthController>().loggedIn, isFalse);
    });
  });
}
