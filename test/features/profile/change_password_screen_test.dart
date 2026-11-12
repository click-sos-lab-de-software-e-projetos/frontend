import 'package:click_sos/data/repositories/auth_repository.dart';
import 'package:click_sos/features/profile/change_password_screen.dart';
import 'package:click_sos/features/profile/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

class _Spy extends FakeAuthRepository {
  final calls = <(String, String)>[];

  @override
  Future<void> changePassword({required String current, required String next}) async {
    calls.add((current, next));
    if (current != 'senha-atual') throw const WrongPasswordException();
  }
}

Future<_Spy> _open(WidgetTester tester, Widget screen) async {
  final auth = _Spy();
  await pumpTestApp(
    tester,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen)),
          child: const Text('abrir'),
        ),
      ),
    ),
    deps: TestDeps(loggedIn: true, auth: auth),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return auth;
}

Future<void> _fill(WidgetTester tester, String current, String next, String confirm) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), current);
  await tester.enterText(fields.at(1), next);
  await tester.enterText(fields.at(2), confirm);
  await tester.tap(find.text('Trocar senha'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the profile editor opens it', (tester) async {
    await _open(tester, const EditProfileScreen());

    await tester.tap(find.text('Trocar senha'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets('a short or unconfirmed new password is not sent', (tester) async {
    final auth = await _open(tester, const ChangePasswordScreen());

    await _fill(tester, 'senha-atual', '1234567', '1234567');
    expect(find.text('A senha precisa ter ao menos 8 caracteres.'), findsOneWidget);

    await _fill(tester, 'senha-atual', '12345678', '12345679');
    expect(find.text('As senhas não conferem.'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('a wrong current password keeps the screen open', (tester) async {
    await _open(tester, const ChangePasswordScreen());

    await _fill(tester, 'errada', '12345678', '12345678');

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    expect(find.text('Senha atual incorreta.'), findsOneWidget);
  });

  testWidgets('success closes and confirms', (tester) async {
    final auth = await _open(tester, const ChangePasswordScreen());

    await _fill(tester, 'senha-atual', '12345678', '12345678');

    expect(auth.calls.single, ('senha-atual', '12345678'));
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.text(ChangePasswordScreen.done), findsOneWidget);
  });
}
