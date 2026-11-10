import 'package:flutter/material.dart';

import '../../../data/models/risk_region.dart';
import '../../../shared/widgets/app_card.dart';

/// Details of the tapped district.
class RegionCard extends StatelessWidget {
  const RegionCard({super.key, required this.region, required this.onClose, required this.onFeedback});

  final RiskRegion region;
  final VoidCallback onClose;
  final VoidCallback onFeedback;

  static String summary(RiskRegion r) => 'Score ${r.score} de 100 · Risco ${r.band.label.toLowerCase()}';

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.location_city, color: region.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(region.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(summary(region), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Fechar', onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
            OutlinedButton.icon(
              onPressed: onFeedback,
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Enviar feedback'),
            ),
          ],
        ),
      );
}
