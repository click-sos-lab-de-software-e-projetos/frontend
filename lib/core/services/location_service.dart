import 'package:geolocator/geolocator.dart';

import 'geo_point.dart';

abstract interface class LocationService {
  /// Current position, or `null` when location is off, denied or unavailable.
  Future<GeoPoint?> currentPosition();
}

/// On Android geolocator uses the FusedLocationProviderClient (Google Play Services).
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<GeoPoint?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.high, forceLocationManager: false),
      );
      return (lat: p.latitude, lng: p.longitude);
    } catch (_) {
      // Location is best effort: callers fall back to a default position.
      return null;
    }
  }
}

class FakeLocationService implements LocationService {
  FakeLocationService([this.position]);

  GeoPoint? position;

  @override
  Future<GeoPoint?> currentPosition() async => position;
}
