import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/geo_point.dart';
import '../../data/models/community_alert.dart';
import '../../data/models/risk_region.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import 'map_controller.dart';
import 'widgets/alert_card.dart';
import 'widgets/alert_markers.dart';
import 'widgets/alert_sheet.dart';
import 'widgets/region_card.dart';
import 'widgets/region_heatmap.dart';

/// TELA 1 — Mapa de risco por distrito (`/mapa/regioes`) com os alertas da comunidade (`/mapa/alertas`).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  static const created = 'Alerta criado. Ele fica no mapa por 24 horas.';
  static const loginToAlert = 'Entre na sua conta para criar um alerta.';
  static const needsLocation = 'Ative a localização para criar um alerta onde você está.';

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _map;
  GeoPoint? _camera;
  Map<AlertCategory, BitmapDescriptor> _icons = const {};
  List<RiskRegion>? _heatRegions;
  late TileOverlay _heat;

  /// Same overlay while the regions don't change, so tiles are not repainted on every build.
  TileOverlay _heatFor(List<RiskRegion> regions) {
    if (!identical(regions, _heatRegions)) {
      _heatRegions = regions;
      _heat = riskHeatOverlay(regions);
    }
    return _heat;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_icons.isEmpty) {
      loadAlertIcons(MediaQuery.devicePixelRatioOf(context)).then((icons) {
        if (mounted) setState(() => _icons = icons);
      });
    }
  }

  Future<void> _init() async {
    final controller = context.read<MapController>();
    await controller.init();
    if (!mounted) return;
    await _map?.animateCamera(CameraUpdate.newLatLng(_latLng(controller.center)));
  }

  Future<void> _createAlert() async {
    final messenger = ScaffoldMessenger.of(context);
    final map = context.read<MapController>();
    if (!context.read<AuthController>().loggedIn) {
      messenger.showSnackBar(const SnackBar(content: Text(MapScreen.loginToAlert)));
      await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
      if (!mounted || !context.read<AuthController>().loggedIn) return;
    }
    final position = await map.alertPosition();
    if (!mounted) return;
    if (position == null) {
      messenger.showSnackBar(const SnackBar(content: Text(MapScreen.needsLocation)));
      return;
    }
    final created = await showAlertSheet(context, position);
    if (created == null) return;
    map.added(created);
    messenger.showSnackBar(const SnackBar(content: Text(MapScreen.created)));
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
    final selectedAlert = map.selectedAlert;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _latLng(map.center), zoom: 12),
            myLocationEnabled: map.locationAllowed,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            tileOverlays: {_heatFor(map.regions)},
            markers: buildAlertMarkers(map.alerts, _icons, onTap: map.selectAlert),
            onTap: (p) => map.selectAt((lat: p.latitude, lng: p.longitude)),
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
                    child: Row(
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
                  ),
                  if (map.error != null) _Notice(text: map.error!, onRetry: map.retry),
                  if (map.error == null && !map.loading && map.regions.isEmpty)
                    const _Notice(text: 'Nenhuma região de risco por aqui.'),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      tooltip: 'Criar alerta',
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      onPressed: _createAlert,
                      child: const Icon(Icons.campaign, size: 30),
                    ),
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 12),
                    RegionCard(region: selected, onClose: () => map.select(null)),
                  ],
                  if (selectedAlert != null) ...[
                    const SizedBox(height: 12),
                    AlertCard(alert: selectedAlert, onClose: () => map.selectAlert(null)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
