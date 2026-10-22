import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../shared/widgets/app_card.dart';
import '../occurrence/occurrence_screen.dart';
import 'occurrences_controller.dart';
import 'widgets/heat_circles.dart';

/// TELA 1 — Mapa de calor colaborativo.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final controller = context.read<OccurrencesController>();
    final messenger = ScaffoldMessenger.of(context);
    final error = await controller.load();
    if (!mounted) return;
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
    await _map?.animateCamera(CameraUpdate.newLatLng(_latLng(controller)));
  }

  LatLng _latLng(OccurrencesController c) => LatLng(c.center.lat, c.center.lng);

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final occurrences = context.watch<OccurrencesController>();
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _latLng(occurrences), zoom: 13),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            circles: buildHeatCircles(occurrences.occurrences),
            onMapCreated: (c) {
              _map = c;
              c.animateCamera(CameraUpdate.newLatLng(_latLng(context.read<OccurrencesController>())));
            },
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: AppCard(
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, color: AppColors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mapa de calor colaborativo de segurança',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Registrar ocorrência'),
        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OccurrenceScreen())),
      ),
    );
  }
}
