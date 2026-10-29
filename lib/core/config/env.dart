import 'package:flutter/foundation.dart';

/// Build-time configuration, set with `--dart-define`:
///
/// ```
/// flutter run --dart-define=USE_FAKE_API=false --dart-define=API_BASE_URL=https://...
/// ```
@immutable
class Env {
  const Env({required this.apiBaseUrl, required this.useFakeApi});

  const Env.fromEnvironment()
      : apiBaseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: defaultApiBaseUrl),
        useFakeApi = const bool.fromEnvironment('USE_FAKE_API', defaultValue: true);

  static const defaultApiBaseUrl = 'https://api.alertaseguro.example/v1';

  final String apiBaseUrl;

  /// There is no backend yet, so fake repositories are the default.
  final bool useFakeApi;
}
