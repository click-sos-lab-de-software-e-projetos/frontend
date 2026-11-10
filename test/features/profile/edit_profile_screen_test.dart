import 'package:alerta_seguro/data/models/user_profile.dart';
import 'package:alerta_seguro/data/repositories/auth_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/profile/edit_profile_screen.dart';
import 'package:alerta_seguro/features/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

class _Offline extends FakeAuthRepository {
  @override
  Future<UserProfile> updateProfile({String? name, String? phone}) async =>
      throw const RepositoryException('Sem conexão.');
}

Future<TestDeps> _open(WidgetTester tester, [FakeAuthRepository? auth]) async {
  final deps = await pumpTestApp(
    tester,
    home: Builder(
      builder: (context) => Scaffold(
        body: Column(
          children: [
            Text('Perfil: ${context.watch<ProfileController>().profile.name}'),
            TextButton(
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const EditProfileScreen())),
              child: const Text('abrir'),
            ),
          ],
        ),
      ),
    ),
    deps: TestDeps(loggedIn: true, auth: auth),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return deps;
}

Finder _field(String text) => find.widgetWithText(TextFormField, text);

void main() {
  const demo = FakeAuthRepository.demoProfile;

  testWidgets('shows the e-mail read-only', (tester) async {
    await _open(tester);

    expect(tester.widget<TextFormField>(_field(demo.email)).enabled, isFalse);
    expect(find.text(EditProfileScreen.emailNotice), findsOneWidget);
  });

  testWidgets('an invalid phone shows an error and is not sent', (tester) async {
    final deps = await _open(tester);

    await tester.enterText(_field(demo.phone), '123');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um telefone válido.'), findsOneWidget);
    expect((await deps.auth.me()).phone, demo.phone);
  });

  testWidgets('saves a new name on the account and closes', (tester) async {
    final deps = await _open(tester);

    await tester.enterText(_field(demo.name), 'Bia Souza');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    expect((await deps.auth.me()).name, 'Bia Souza');
    expect(find.text('Perfil: Bia Souza'), findsOneWidget);
  });

  testWidgets('a failure keeps the screen open with the message', (tester) async {
    await _open(tester, _Offline());

    await tester.enterText(_field(demo.name), 'Bia');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('Sem conexão.'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Salvar')).onPressed, isNotNull);
  });
}
