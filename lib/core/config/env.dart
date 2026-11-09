import 'package:flutter/foundation.dart';

/// Build-time configuration, set with `--dart-define`:
///
/// ```
/// flutter run --dart-define=USE_FAKE_API=false --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
/// ```
@immutable
class Env {
  const Env({required this.apiBaseUrl, required this.useFakeApi});

  const Env.fromEnvironment()
      : apiBaseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: defaultApiBaseUrl),
        useFakeApi = const bool.fromEnvironment('USE_FAKE_API', defaultValue: true);

  /// The local backend as seen from the Android emulator (`10.0.2.2` is the host machine).
  static const defaultApiBaseUrl = 'http://10.0.2.2:8000/api/v1';

  final String apiBaseUrl;

  /// Demo mode (fake repositories) stays the default so the app runs without a backend.
  final bool useFakeApi;
}
