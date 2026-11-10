import 'package:alerta_seguro/app/app.dart';
import 'package:alerta_seguro/app/dependencies.dart';
import 'package:alerta_seguro/core/network/session.dart';
import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/core/services/whatsapp_service.dart';
import 'package:alerta_seguro/data/fakes/demo_seed.dart';
import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/repositories/alert_repository.dart';
import 'package:alerta_seguro/data/repositories/auth_repository.dart';
import 'package:alerta_seguro/data/repositories/contact_repository.dart';
import 'package:alerta_seguro/data/repositories/region_repository.dart';
import 'package:alerta_seguro/data/repositories/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake dependencies whose state tests can inspect. With [loggedIn] the app
/// starts with an active session, so contacts are loaded from [contacts].
class TestDeps {
  TestDeps({
    List<Contact>? contacts,
    ContactRepository? repository,
    this.location,
    bool loggedIn = false,
    FakeRegionRepository? regions,
    FakeAuthRepository? auth,
  })  : auth = auth ?? FakeAuthRepository(),
        contacts = repository ?? FakeContactRepository(contacts ?? DemoSeed.contacts),
        regions = regions ?? FakeRegionRepository() {
    // The fake auth must know the account too: the app fetches /auth/me for a restored session.
    if (loggedIn) {
      this.auth.login(email: FakeAuthRepository.demoProfile.email, password: 'test');
      session.start('test-token');
    }
  }

  final session = Session();
  final FakeAuthRepository auth;
  final ContactRepository contacts;
  final alerts = FakeAlertRepository();
  final FakeRegionRepository regions;
  final launched = <Uri>[];
  final FakeLocationService? location;

  AppDependencies build() => AppDependencies(
        session: session,
        repositories: Repositories(auth: auth, contacts: contacts, alerts: alerts, regions: regions),
        location: location ?? FakeLocationService(),
        whatsApp: WhatsAppService(
          launcher: (uri) async {
            launched.add(uri);
            return true;
          },
        ),
      );
}

Future<TestDeps> pumpTestApp(WidgetTester tester, {Widget? home, TestDeps? deps}) async {
  final d = deps ?? TestDeps();
  await tester.pumpWidget(
    home == null ? AlertaApp(dependencies: d.build()) : AlertaApp(dependencies: d.build(), home: home),
  );
  // A second frame lets async loads (e.g. contacts after login) complete.
  await tester.pump();
  await tester.pump();
  return d;
}
