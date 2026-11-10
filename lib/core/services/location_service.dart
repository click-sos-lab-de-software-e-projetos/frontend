import 'package:geolocator/geolocator.dart';

import 'geo_point.dart';

/// Whether the app can read the location, and why not.
enum LocationAccess {
  granted,

  /// Not granted yet, but the system dialog can still be shown.
  canAsk,
  denied,

  /// Only the system settings can grant it now.
  deniedForever,

  /// Location (GPS) is turned off on the device.
  serviceOff,
}

abstract interface class LocationService {
  /// Current position, or `null` when location is off, denied or unavailable.
  /// Asks for permission when needed.
  Future<GeoPoint?> currentPosition();

  Future<LocationAccess> checkAccess();

  /// Shows the system permission dialog.
  Future<LocationAccess> requestAccess();

  /// Opens the device's location settings ([LocationAccess.serviceOff]) or the app's settings.
  Future<void> openSettings(LocationAccess reason);
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

  @override
  Future<LocationAccess> checkAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
      return _fromPermission(await Geolocator.checkPermission(), asked: false);
    } catch (_) {
      return LocationAccess.denied;
    }
  }

  @override
  Future<LocationAccess> requestAccess() async {
    try {
      return _fromPermission(await Geolocator.requestPermission(), asked: true);
    } catch (_) {
      return LocationAccess.denied;
    }
  }

  @override
  Future<void> openSettings(LocationAccess reason) async {
    if (reason == LocationAccess.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  static LocationAccess _fromPermission(LocationPermission p, {required bool asked}) => switch (p) {
        LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        // Android reports "denied" both before asking and after one refusal; asking again is allowed.
        LocationPermission.denied ||
        LocationPermission.unableToDetermine =>
          asked ? LocationAccess.denied : LocationAccess.canAsk,
      };
}

class FakeLocationService implements LocationService {
  FakeLocationService([this.position]);

  GeoPoint? position;
  LocationAccess access = LocationAccess.granted;

  /// What [requestAccess] answers (and keeps) when the dialog is shown.
  LocationAccess afterRequest = LocationAccess.granted;
  int requests = 0;
  final List<LocationAccess> openedSettings = [];

  @override
  Future<GeoPoint?> currentPosition() async => position;

  @override
  Future<LocationAccess> checkAccess() async => access;

  @override
  Future<LocationAccess> requestAccess() async {
    requests++;
    return access = afterRequest;
  }

  @override
  Future<void> openSettings(LocationAccess reason) async => openedSettings.add(reason);
}
