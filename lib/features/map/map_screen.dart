import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/geo_point.dart';
import '../../data/models/risk_region.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import 'map_controller.dart';
import 'widgets/feedback_sheet.dart';
import 'widgets/region_card.dart';
import 'widgets/region_circles.dart';

/// TELA 1 — Mapa de risco por distrito (`/mapa/regioes`).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  static const thanks = 'Obrigado! Seu relato fica pendente de análise e não muda o mapa.';
  static const loginToFeedback = 'Entre na sua conta para enviar feedback.';

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _map;
  GeoPoint? _camera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final controller = context.read<MapController>();
    await controller.init();
    if (!mounted) return;
    await _map?.animateCamera(CameraUpdate.newLatLng(_latLng(controller.center)));
  }

  Future<void> _feedback(RiskRegion region) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!context.read<AuthController>().loggedIn) {
      messenger.showSnackBar(const SnackBar(content: Text(MapScreen.loginToFeedback)));
      await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
      if (!mounted || !context.read<AuthController>().loggedIn) return;
    }
    if (await showFeedbackSheet(context, region)) {
      messenger.showSnackBar(const SnackBar(content: Text(MapScreen.thanks)));
    }
  }

  static LatLng _latLng(GeoPoint p) => LatLng(p.lat, p.lng);

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapController>();
    final selected = map.selected;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _latLng(map.center), zoom: 12),
            myLocationEnabled: map.locationAllowed,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            circles: buildRegionCircles(map.regions, onTap: map.select),
            onTap: (_) => map.select(null),
            onCameraMove: (p) => _camera = (lat: p.target.latitude, lng: p.target.longitude),
            onCameraIdle: () {
              final camera = _camera;
              if (camera != null) map.cameraIdle(camera);
            },
            onMapCreated: (c) => _map = c,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: AppColors.red),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('Mapa de risco por distrito', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            if (map.loading)
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const _Legend(),
                      ],
                    ),
                  ),
                  if (map.error != null) _Notice(text: map.error!, onRetry: map.retry),
                  if (map.error == null && !map.loading && map.regions.isEmpty)
                    const _Notice(text: 'Nenhuma região de risco por aqui.'),
                  const Spacer(),
                  if (selected != null)
                    RegionCard(
                      region: selected,
                      onClose: () => map.select(null),
                      onFeedback: () => _feedback(selected),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final band in RiskBand.values) ...[
            Icon(Icons.circle, size: 10, color: band.color),
            const SizedBox(width: 4),
            Text(band.label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
            const SizedBox(width: 12),
          ],
        ],
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AppCard(
          child: Row(
            children: [
              Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white70))),
              if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
            ],
          ),
        ),
      );
}
