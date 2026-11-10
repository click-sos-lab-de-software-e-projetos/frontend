import 'package:dio/dio.dart';

import '../models/contact.dart';
import 'alert_repository.dart';
import 'auth_repository.dart';
import 'contact_repository.dart';
import 'occurrence_repository.dart';
import 'region_repository.dart';

class Repositories {
  const Repositories({
    required this.auth,
    required this.contacts,
    required this.occurrences,
    required this.alerts,
    required this.regions,
  });

  factory Repositories.fake({List<Contact> contacts = const []}) => Repositories(
        auth: FakeAuthRepository(),
        contacts: FakeContactRepository(contacts),
        occurrences: FakeOccurrenceRepository(),
        alerts: FakeAlertRepository(),
        regions: FakeRegionRepository(),
      );

  factory Repositories.http(Dio dio) => Repositories(
        auth: HttpAuthRepository(dio),
        contacts: HttpContactRepository(dio),
        occurrences: HttpOccurrenceRepository(dio),
        alerts: HttpAlertRepository(dio),
        regions: HttpRegionRepository(dio),
      );

  final AuthRepository auth;
  final ContactRepository contacts;
  final OccurrenceRepository occurrences;
  final AlertRepository alerts;
  final RegionRepository regions;
}
