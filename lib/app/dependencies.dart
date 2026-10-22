import '../core/config/env.dart';
import '../core/services/location_service.dart';
import '../core/services/whatsapp_service.dart';
import '../data/fakes/demo_seed.dart';
import '../data/models/contact.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/repositories.dart';

/// Everything the app needs from the outside world; swapped for fakes in tests.
class AppDependencies {
  const AppDependencies({
    required this.repositories,
    this.location = const GeolocatorLocationService(),
    this.whatsApp = const WhatsAppService(),
    this.initialProfile = UserProfile.empty,
    this.initialContacts = const [],
  });

  factory AppDependencies.fromEnv(Env env) =>
      env.useFakeApi ? AppDependencies.demo() : AppDependencies(repositories: Repositories.fromEnv(env));

  /// Fake repositories plus demo seed data.
  factory AppDependencies.demo({
    LocationService location = const GeolocatorLocationService(),
    WhatsAppService whatsApp = const WhatsAppService(),
  }) =>
      AppDependencies(
        repositories: Repositories.fake(),
        location: location,
        whatsApp: whatsApp,
        initialProfile: DemoSeed.profile,
        initialContacts: DemoSeed.contacts,
      );

  final Repositories repositories;
  final LocationService location;
  final WhatsAppService whatsApp;
  final UserProfile initialProfile;
  final List<Contact> initialContacts;
}
