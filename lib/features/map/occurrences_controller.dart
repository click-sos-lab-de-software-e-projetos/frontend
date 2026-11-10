import 'package:flutter/foundation.dart';

import '../../data/models/occurrence_report.dart';
import '../../data/repositories/occurrence_repository.dart';
import '../../data/repositories/repository_exception.dart';

/// Sends occurrence reports. The map itself comes from `/mapa/regioes` (see `MapController`).
class OccurrencesController extends ChangeNotifier {
  OccurrencesController(this._repository);

  final OccurrenceRepository _repository;

  /// Throws [RepositoryException] on failure.
  Future<void> report(OccurrenceReport report) => _repository.report(report);
}
