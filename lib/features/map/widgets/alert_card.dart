import 'package:flutter/material.dart';

import '../../../data/models/community_alert.dart';
import '../../../shared/widgets/app_card.dart';
import 'alert_markers.dart';

/// Details of the tapped alert.
class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, required this.onClose, this.now});

  final CommunityAlert alert;
  final VoidCallback onClose;

  /// For tests; defaults to the clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: alertColor(alert.category),
              child: Icon(alert.category.icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.category.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(
                    'Alerta da comunidade · ${CommunityAlert.age(alert.createdAt, now ?? DateTime.now())}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (alert.text != null) ...[
                    const SizedBox(height: 6),
                    Text(alert.text!),
                  ],
                ],
              ),
            ),
            IconButton(tooltip: 'Fechar', onPressed: onClose, icon: const Icon(Icons.close)),
          ],
        ),
      );
}
