import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// No Android o geolocator usa o FusedLocationProviderClient (Google Play Services).
Future<LatLng?> currentPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) return null;
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
  if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
  try {
    final p = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.high, forceLocationManager: false));
    return LatLng(p.latitude, p.longitude);
  } catch (_) {
    return null;
  }
}

Future<bool> openWhatsApp(String phone, String text) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (!digits.startsWith('55')) digits = '55$digits';
  return launchUrl(Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(text)}'),
      mode: LaunchMode.externalApplication);
}

String mapsLink(LatLng p) => 'https://maps.google.com/?q=${p.latitude},${p.longitude}';
