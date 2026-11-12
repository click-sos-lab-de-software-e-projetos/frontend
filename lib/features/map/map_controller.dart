import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/services/geo_point.dart';
import '../../core/services/location_service.dart';
import '../../data/models/risk_region.dart';
import '../../data/repositories/region_repository.dart';
import '../../data/repositories/repository_exception.dart';

/// Risk regions around the map center. `/mapa/regioes` is public, so the map
/// loads with or without a session.
class MapController extends ChangeNotifier {
  MapController({
    required RegionRepository regions,
    required LocationService location,
    this.idleDelay = const Duration(milliseconds: 500),
  })  : _regions = regions,
        _location = location;

  /// São Paulo (Praça da Sé), used without location permission.
  static const GeoPoint defaultCenter = (lat: -23.5505, lng: -46.6333);

  /// The camera must move this far from the last query to load again.
  static const reloadDistanceMeters = 2000.0;

  final RegionRepository _regions;
  final LocationService _location;
  final Duration idleDelay;

  GeoPoint _center = defaultCenter;
  GeoPoint? _lastQuery;
  bool _locationAllowed = false;
  List<RiskRegion> _list = const [];
  bool _loading = false;
  String? _error;
  String? _selectedId;
  Timer? _idle;
  int _run = 0;

  GeoPoint get center => _center;
  bool get locationAllowed => _locationAllowed;
  List<RiskRegion> get regions => _list;
  bool get loading => _loading;
  String? get error => _error;

  RiskRegion? get selected {
    for (final r in _list) {
      if (r.id == _selectedId) return r;
    }
    return null;
  }

  /// Centers on the user only if permission was already given; the map never asks for it (MAPM-03).
  Future<void> init() async {
    _locationAllowed = await _location.checkAccess() == LocationAccess.granted;
    if (_locationAllowed) _center = await _location.currentPosition() ?? _center;
    notifyListeners();
    await _load(_center);
  }

  Future<void> retry() => _load(_lastQuery ?? _center);

  /// Called when the camera stops; loads again after [idleDelay] if it moved far enough.
  void cameraIdle(GeoPoint position) {
    _center = position;
    _idle?.cancel();
    _idle = Timer(idleDelay, () {
      final last = _lastQuery;
      if (last == null || _distanceMeters(last, position) > reloadDistanceMeters) _load(position);
    });
  }

  void select(String? id) {
    if (id == _selectedId) return;
    _selectedId = id;
    notifyListeners();
  }

  Future<void> _load(GeoPoint at) async {
    final run = ++_run;
    _lastQuery = at;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final found = await _regions.fetchNearby(lat: at.lat, lng: at.lng);
      if (run != _run) return;
      _list = List.unmodifiable(found);
    } on RepositoryException catch (e) {
      if (run != _run) return;
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  static double _distanceMeters(GeoPoint a, GeoPoint b) {
    const earth = 6371000.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(b.lat - a.lat);
    final dLng = rad(b.lng - a.lng);
    final h = pow(sin(dLat / 2), 2) + cos(rad(a.lat)) * cos(rad(b.lat)) * pow(sin(dLng / 2), 2);
    return 2 * earth * asin(sqrt(h));
  }

  @override
  void dispose() {
    _idle?.cancel();
    super.dispose();
  }
}
