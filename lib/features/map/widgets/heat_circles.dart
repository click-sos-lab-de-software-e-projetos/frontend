import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/theme.dart';
import '../../../data/models/occurrence.dart';

/// google_maps_flutter has no native heat-map layer, so heat is simulated with
/// overlapping translucent circles (more occurrences → more intense).
Set<Circle> buildHeatCircles(List<Occurrence> occurrences) {
  final out = <Circle>{};
  var id = 0;
  for (final o in occurrences) {
    final color = switch (o.severity) {
      3 => AppColors.red,
      2 => Colors.orange,
      _ => Colors.yellow,
    };
    for (final (radius, alpha) in const [(450.0, .10), (280.0, .16), (130.0, .26)]) {
      out.add(
        Circle(
          circleId: CircleId('c${id++}'),
          center: LatLng(o.lat, o.lng),
          radius: radius,
          fillColor: color.withValues(alpha: alpha),
          strokeWidth: 0,
        ),
      );
    }
  }
  return out;
}
