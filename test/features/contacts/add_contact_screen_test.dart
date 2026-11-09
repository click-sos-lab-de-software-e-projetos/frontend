import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/repositories/contact_repository.dart';
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

  testWidgets('pending contact gets a consent request link over WhatsApp; status refreshes on resume', (tester) async {
    final repo = _CountingRepo(const [Contact(id: 'p', name: 'Bia', phone: '+5511900001234')]);
    final deps = TestDeps(loggedIn: true, repository: repo);
    await pumpTestApp(tester, home: const Scaffold(body: ProfileScreen()), deps: deps);
    final loadsBefore = repo.lists;

    await tester.tap(find.byTooltip('Enviar pedido de consentimento'));
    await tester.pumpAndSettle();

    final uri = deps.launched.single;
    expect(uri.host, 'wa.me');
    expect(uri.path, '/5511900001234');
    expect(uri.queryParameters['text'], contains('#token=fake-p'));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.lists, loadsBefore + 1);
  });

  testWidgets('shows refused and confirmed statuses', (tester) async {
    await pumpTestApp(
      tester,
      home: const Scaffold(body: ProfileScreen()),
      deps: TestDeps(
        loggedIn: true,
        contacts: [
          Contact(id: 'r', name: 'Caio', phone: '+1', refusedAt: DateTime.utc(2026)),
          Contact(id: 'c', name: 'Dani', phone: '+2', consentedAt: DateTime.utc(2026)),
        ],
      ),
    );

    expect(find.text('+1 · Recusou receber alertas'), findsOneWidget);
    expect(find.text('+2 · Consentimento confirmado'), findsOneWidget);
    expect(find.byTooltip('Enviar pedido de consentimento'), findsOneWidget);
  });
}

class _CountingRepo extends FakeContactRepository {
  _CountingRepo(super.initial);

  int lists = 0;

  @override
  Future<List<Contact>> list() {
    lists++;
    return super.list();
  }
}
