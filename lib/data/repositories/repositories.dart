import 'package:dio/dio.dart';

import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import 'alert_repository.dart';
import 'auth_repository.dart';
import 'occurrence_repository.dart';

class Repositories {
  const Repositories({required this.auth, required this.occurrences, required this.alerts});

  factory Repositories.fake() => Repositories(
        auth: FakeAuthRepository(),
        occurrences: FakeOccurrenceRepository(),
        alerts: FakeAlertRepository(),
      );

  factory Repositories.http(Dio dio) => Repositories(
        auth: HttpAuthRepository(dio),
        occurrences: HttpOccurrenceRepository(dio),
        alerts: HttpAlertRepository(dio),
      );

  factory Repositories.fromEnv(Env env) => env.useFakeApi ? Repositories.fake() : Repositories.http(buildDio(env));

  final AuthRepository auth;
  final OccurrenceRepository occurrences;
  final AlertRepository alerts;
}
