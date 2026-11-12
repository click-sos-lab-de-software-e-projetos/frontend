import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/community_alert.dart';

/// Pin color of each category.
Color alertColor(AlertCategory c) => switch (c) {
      AlertCategory.robbery => const Color(0xFFDC2626),
      AlertCategory.harassment => const Color(0xFF9333EA),
      AlertCategory.lighting => const Color(0xFFD97706),
      AlertCategory.lowMovement => const Color(0xFF475569),
      AlertCategory.lowPolicing => const Color(0xFF2563EB),
      AlertCategory.other => const Color(0xFFEA580C),
    };

const _size = 40.0;

/// Round pins with the category icon, like Waze reports. Drawn once per category.
Future<Map<AlertCategory, BitmapDescriptor>> loadAlertIcons(double pixelRatio) async => {
      for (final c in AlertCategory.values)
        c: BitmapDescriptor.bytes(await _draw(c, pixelRatio), width: _size, height: _size),
    };

Future<Uint8List> _draw(AlertCategory c, double ratio) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(ratio);
  const center = Offset(_size / 2, _size / 2);
  canvas
    ..drawCircle(center + const Offset(0, 1.5), _size / 2 - 2, Paint()..color = const Color(0x55000000))
    ..drawCircle(center, _size / 2 - 2, Paint()..color = Colors.white)
    ..drawCircle(center, _size / 2 - 4.5, Paint()..color = alertColor(c));
  final glyph = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(c.icon.codePoint),
      style: TextStyle(fontSize: 22, fontFamily: c.icon.fontFamily, package: c.icon.fontPackage, color: Colors.white),
    ),
  )..layout();
  glyph.paint(canvas, center - Offset(glyph.width / 2, glyph.height / 2));
  final image = await recorder.endRecording().toImage((_size * ratio).round(), (_size * ratio).round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

/// One marker per alert, at the place where it was created.
Set<Marker> buildAlertMarkers(
  List<CommunityAlert> alerts,
  Map<AlertCategory, BitmapDescriptor> icons, {
  required void Function(String id) onTap,
}) =>
    {
      for (final a in alerts)
        Marker(
          markerId: MarkerId(a.id),
          position: LatLng(a.position.lat, a.position.lng),
          icon: icons[a.category] ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(.5, .5),
          consumeTapEvents: true,
          onTap: () => onTap(a.id),
        ),
    };
