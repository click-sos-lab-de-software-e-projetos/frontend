import 'package:click_sos/data/fakes/demo_seed.dart';
import 'package:click_sos/data/models/contact.dart';
import 'package:click_sos/data/repositories/contact_repository.dart';
import 'package:click_sos/data/repositories/repository_exception.dart';
import 'package:click_sos/features/auth/auth_controller.dart';
import 'package:click_sos/features/contacts/add_contact_screen.dart';
import 'package:click_sos/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('logged out: no contacts and a login prompt', (tester) async {
    await pumpTestApp(tester, home: const Scaffold(body: ProfileScreen()));

    expect(find.text('Contatos de confiança'), findsOneWidget);
    expect(find.text('+ ADICIONAR'), findsNothing);
    expect(find.text('Fazer login'), findsOneWidget);
  });

  testWidgets('adding a contact validates, converts the phone to E.164 and lists it', (tester) async {
    final deps = await pumpTestApp(
      tester,
      home: const Scaffold(body: ProfileScreen()),
      deps: TestDeps(contacts: const [], loggedIn: true),
    );
    expect(find.text('Contatos de confiança (0)'), findsOneWidget);

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

    expect(find.text('Contatos de confiança (1)'), findsOneWidget);
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
    expect(find.text('Contatos de confiança'), findsOneWidget);
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

  group('editing', () {
    Future<TestDeps> open(WidgetTester tester, String name, {ContactRepository? repository}) async {
      final deps = await pumpTestApp(
        tester,
        home: const Scaffold(body: ProfileScreen()),
        deps: TestDeps(loggedIn: true, repository: repository),
      );
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      return deps;
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
    }

    testWidgets('tapping a contact opens it filled and saves a new name', (tester) async {
      final deps = await open(tester, 'Contato Exemplo 2');

      expect(find.text('Editar contato'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '+5511900000002'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Contato Exemplo 2'), 'Bia');
      await save(tester);

      expect(find.byType(AddContactScreen), findsNothing);
      expect(find.text('Bia'), findsOneWidget);
      expect((await deps.contacts.list()).last.name, 'Bia');
    });

    testWidgets('a new phone for a contact who answered asks before saving', (tester) async {
      final deps = await open(tester, 'Contato Exemplo 1');

      await tester.enterText(find.widgetWithText(TextFormField, '+5511900000001'), '(11) 91111-1111');
      await save(tester);
      expect(find.text(AddContactScreen.reconsentWarning), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(AddContactScreen), findsOneWidget);
      expect((await deps.contacts.list()).first.phone, '+5511900000001');

      await save(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.byType(AddContactScreen), findsNothing);
      expect(find.text('+5511911111111 · Aguardando consentimento'), findsOneWidget);
    });

    testWidgets('a pending contact gets the new phone without asking', (tester) async {
      final deps = await open(tester, 'Contato Exemplo 2');

      await tester.enterText(find.widgetWithText(TextFormField, '+5511900000002'), '(11) 92222-2222');
      await save(tester);

      expect(find.text(AddContactScreen.reconsentWarning), findsNothing);
      expect((await deps.contacts.list()).last.phone, '+5511922222222');
    });

    testWidgets('removing asks for confirmation', (tester) async {
      final deps = await open(tester, 'Contato Exemplo 2');

      await tester.tap(find.text('Remover contato'));
      await tester.pumpAndSettle();
      expect(find.text('Remover Contato Exemplo 2?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await deps.contacts.list(), hasLength(2));

      await tester.tap(find.text('Remover contato'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();

      expect(find.byType(AddContactScreen), findsNothing);
      expect(find.text('Contato Exemplo 2'), findsNothing);
      expect((await deps.contacts.list()).map((c) => c.id), ['demo-1']);
    });

    testWidgets('a failed removal keeps the screen and explains', (tester) async {
      await open(tester, 'Contato Exemplo 2', repository: _FailingDelete());

      await tester.tap(find.text('Remover contato'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();

      expect(find.byType(AddContactScreen), findsOneWidget);
      expect(find.text('Sem conexão.'), findsOneWidget);
    });
  });
}

class _FailingDelete extends FakeContactRepository {
  _FailingDelete() : super(DemoSeed.contacts);

  @override
  Future<void> delete(String id) async => throw const RepositoryException('Sem conexão.');
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
