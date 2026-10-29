import 'package:flutter/foundation.dart';

import '../../core/services/geo_point.dart';
import '../../core/services/location_service.dart';
import '../../data/models/occurrence.dart';
import '../../data/models/occurrence_report.dart';
import '../../data/repositories/occurrence_repository.dart';
import '../../data/repositories/repository_exception.dart';

class OccurrencesController extends ChangeNotifier {
  OccurrencesController(this._repository, this._location);

  /// São Paulo (Praça da Sé), used when the location is unavailable.
  static const GeoPoint defaultCenter = (lat: -23.5505, lng: -46.6333);

  final OccurrenceRepository _repository;
  final LocationService _location;

  GeoPoint _center = defaultCenter;
  List<Occurrence> _occurrences = const [];
  bool _loading = false;

  GeoPoint get center => _center;
  List<Occurrence> get occurrences => _occurrences;
  bool get loading => _loading;

  /// Loads occurrences around the user. Returns a user-facing error message, or null.
  Future<String?> load() async {
    _loading = true;
    notifyListeners();
    try {
      _center = await _location.currentPosition() ?? _center;
      _occurrences = List.unmodifiable(await _repository.fetchNearby(lat: _center.lat, lng: _center.lng));
      return null;
    } on RepositoryException catch (e) {
      return e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sends the report and, if it has coordinates, shows it on the map.
  /// Throws [RepositoryException] on failure.
  Future<void> report(OccurrenceReport report) async {
    await _repository.report(report);
    if (report.lat != null && report.lng != null) {
      _occurrences = List.unmodifiable([
        ..._occurrences,
        Occurrence(lat: report.lat!, lng: report.lng!, severity: 3, type: report.type),
      ]);
      notifyListeners();
    }
  }
}
