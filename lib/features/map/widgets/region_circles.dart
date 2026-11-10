import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/risk_region.dart';

/// One circle per district, with the center, radius and color from the API.
Set<Circle> buildRegionCircles(List<RiskRegion> regions, {required void Function(String id) onTap}) => {
      for (final r in regions)
        Circle(
          circleId: CircleId(r.id),
          center: LatLng(r.center.lat, r.center.lng),
          radius: r.radiusMeters,
          fillColor: r.color.withValues(alpha: .3),
          strokeColor: r.color.withValues(alpha: .8),
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () => onTap(r.id),
        ),
    };
