import 'package:alerta_seguro/app/app.dart';
import 'package:alerta_seguro/app/dependencies.dart';
import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/core/services/whatsapp_service.dart';
import 'package:alerta_seguro/data/fakes/demo_seed.dart';
import 'package:alerta_seguro/data/models/contact.dart';
import 'package:alerta_seguro/data/repositories/alert_repository.dart';
import 'package:alerta_seguro/data/repositories/auth_repository.dart';
import 'package:alerta_seguro/data/repositories/occurrence_repository.dart';
import 'package:alerta_seguro/data/repositories/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake dependencies whose state tests can inspect.
class TestDeps {
  TestDeps({List<Contact> contacts = DemoSeed.contacts, this.location}) : _contacts = contacts;

  final auth = FakeAuthRepository();
  final occurrences = FakeOccurrenceRepository();
  final alerts = FakeAlertRepository();
  final launched = <Uri>[];
  final List<Contact> _contacts;
  final FakeLocationService? location;

  AppDependencies build() => AppDependencies(
        repositories: Repositories(auth: auth, occurrences: occurrences, alerts: alerts),
        location: location ?? FakeLocationService(),
        whatsApp: WhatsAppService(
          launcher: (uri) async {
            launched.add(uri);
            return true;
          },
        ),
        initialProfile: DemoSeed.profile,
        initialContacts: _contacts,
      );
}

Future<TestDeps> pumpTestApp(WidgetTester tester, {Widget? home, TestDeps? deps}) async {
  final d = deps ?? TestDeps();
  await tester.pumpWidget(
    home == null ? AlertaApp(dependencies: d.build()) : AlertaApp(dependencies: d.build(), home: home),
  );
  await tester.pump();
  return d;
}
