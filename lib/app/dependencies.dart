import '../core/config/env.dart';
import '../core/network/api_client.dart';
import '../core/network/session.dart';
import '../core/network/token_store.dart';
import '../core/services/location_service.dart';
import '../core/services/whatsapp_service.dart';
import '../data/fakes/demo_seed.dart';
import '../data/repositories/repositories.dart';

/// Everything the app needs from the outside world; swapped for fakes in tests.
class AppDependencies {
  AppDependencies({
    required this.repositories,
    Session? session,
    this.location = const GeolocatorLocationService(),
    this.whatsApp = const WhatsAppService(),
  }) : session = session ?? Session();

  factory AppDependencies.fromEnv(Env env) {
    if (env.useFakeApi) return AppDependencies.demo();
    final session = Session(store: const SecureTokenStore());
    return AppDependencies(session: session, repositories: Repositories.http(buildDio(env, session: session)));
  }

  /// Fake repositories with demo contacts.
  factory AppDependencies.demo({
    LocationService location = const GeolocatorLocationService(),
    WhatsAppService whatsApp = const WhatsAppService(),
  }) =>
      AppDependencies(
        repositories: Repositories.fake(contacts: DemoSeed.contacts),
        location: location,
        whatsApp: whatsApp,
      );

  final Repositories repositories;

  /// Shared with the HTTP client, which sends its token.
  final Session session;
  final LocationService location;
  final WhatsAppService whatsApp;
}
