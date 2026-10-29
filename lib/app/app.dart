import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/location_service.dart';
import '../core/services/whatsapp_service.dart';
import '../data/repositories/alert_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/occurrence_repository.dart';
import '../features/auth/auth_controller.dart';
import '../features/contacts/contacts_controller.dart';
import '../features/map/occurrences_controller.dart';
import '../features/profile/profile_controller.dart';
import '../features/settings/sos_settings_controller.dart';
import '../features/sos/sos_controller.dart';
import 'dependencies.dart';
import 'shell.dart';
import 'theme.dart';

class AlertaApp extends StatelessWidget {
  const AlertaApp({super.key, required this.dependencies, this.home = const Shell()});

  final AppDependencies dependencies;

  /// Overridable so widget tests can pump a single screen with real providers.
  final Widget home;

  @override
  Widget build(BuildContext context) {
    final d = dependencies;
    return MultiProvider(
      providers: [
        Provider<LocationService>.value(value: d.location),
        Provider<WhatsAppService>.value(value: d.whatsApp),
        Provider<AuthRepository>.value(value: d.repositories.auth),
        Provider<OccurrenceRepository>.value(value: d.repositories.occurrences),
        Provider<AlertRepository>.value(value: d.repositories.alerts),
        ChangeNotifierProvider(create: (c) => AuthController(c.read<AuthRepository>())),
        ChangeNotifierProvider(create: (_) => ProfileController(d.initialProfile)),
        ChangeNotifierProvider(create: (_) => ContactsController(initial: d.initialContacts)),
        ChangeNotifierProvider(create: (_) => SosSettingsController()),
        ChangeNotifierProvider(
          create: (c) => OccurrencesController(c.read<OccurrenceRepository>(), c.read<LocationService>()),
        ),
        Provider(
          create: (c) => SosController(
            alerts: c.read<AlertRepository>(),
            location: c.read<LocationService>(),
            contacts: c.read<ContactsController>(),
            settings: c.read<SosSettingsController>(),
            profile: c.read<ProfileController>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Alerta Seguro',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: home,
      ),
    );
  }
}
