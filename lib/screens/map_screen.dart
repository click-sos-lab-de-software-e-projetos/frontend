import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../api.dart';
import '../services.dart';
import '../state.dart';
import '../ui.dart';
import 'occurrence_screen.dart';

/// TELA 1 — Mapa de calor colaborativo.
/// O google_maps_flutter não tem camada Heatmap nativa, então simulamos o calor
/// com círculos sobrepostos (quanto mais ocorrências, mais intenso).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng center = const LatLng(-23.5505, -46.6333);
  final app = AppState.I;

  @override
  void initState() {
    super.initState();
    app.addListener(() => mounted ? setState(() {}) : null);
    _load();
  }

  Future<void> _load() async {
    final p = await currentPosition();
    if (p != null) center = p;
    try {
      final r = await api.getOccurrences(center.latitude, center.longitude, 5000);
      app.occurrences
        ..clear()
        ..addAll(r.map((e) => Occurrence(LatLng(e['lat'], e['lng']), e['severity'] ?? 1, e['type'] ?? '')));
    } catch (_) {
      // Backend indisponível: dados fictícios para demonstração.
      final rnd = Random(7);
      app.occurrences
        ..clear()
        ..addAll(List.generate(40, (_) => Occurrence(
            LatLng(center.latitude + (rnd.nextDouble() - .5) * .04, center.longitude + (rnd.nextDouble() - .5) * .04),
            1 + rnd.nextInt(3), 'Ocorrência')));
    }
    if (mounted) setState(() {});
  }

  Set<Circle> get _heat {
    final out = <Circle>{};
    var id = 0;
    for (final o in app.occurrences) {
      final c = o.severity == 3 ? kRed : (o.severity == 2 ? Colors.orange : Colors.yellow);
      for (final (r, a) in [(450.0, .10), (280.0, .16), (130.0, .26)]) {
        out.add(Circle(circleId: CircleId('c${id++}'), center: o.pos, radius: r,
            fillColor: c.withOpacity(a), strokeWidth: 0));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 13),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            circles: _heat,
            onMapCreated: (c) => c.animateCamera(CameraUpdate.newLatLng(center)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: box(
                child: Row(children: const [
                  Icon(Icons.local_fire_department, color: kRed),
                  SizedBox(width: 10),
                  Expanded(child: Text('Mapa de calor colaborativo de segurança', style: TextStyle(fontWeight: FontWeight.w700))),
                ]),
              ),
            ),
          ),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kCyan,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add_location_alt),
          label: const Text('Registrar ocorrência'),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const OccurrenceScreen()));
            setState(() {});
          },
        ),
      );
}
