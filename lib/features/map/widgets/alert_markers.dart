import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

/// Round pin with the category icon, like Waze reports.
class AlertPin extends StatelessWidget {
  const AlertPin(this.category, {super.key});

  final AlertCategory category;

  @override
  Widget build(BuildContext context) => Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: alertColor(category),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 1.5))],
        ),
        child: Icon(category.icon, size: 22, color: Colors.white),
      );
}

/// One marker per alert, at the place where it was created.
List<Marker> buildAlertMarkers(List<CommunityAlert> alerts, {required void Function(String id) onTap}) => [
      for (final a in alerts)
        Marker(
          key: ValueKey('alerta-${a.id}'),
          point: LatLng(a.position.lat, a.position.lng),
          width: _size,
          height: _size,
          child: GestureDetector(onTap: () => onTap(a.id), child: AlertPin(a.category)),
        ),
    ];
