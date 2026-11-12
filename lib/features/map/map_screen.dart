import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/geo_point.dart';
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
  final _map = fm.MapController();
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final controller = context.read<MapController>();
    await controller.init();
    if (!mounted) return;
    if (_mapReady) _map.move(_latLng(controller.center), _map.camera.zoom);
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
    _map.dispose();
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
          fm.FlutterMap(
            mapController: _map,
            options: fm.MapOptions(
              initialCenter: _latLng(map.center),
              initialZoom: 12,
              interactionOptions: const fm.InteractionOptions(
                flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
              ),
              onMapReady: () => _mapReady = true,
              onTap: (_, p) => map.selectAt((lat: p.latitude, lng: p.longitude)),
              onPositionChanged: (camera, _) =>
                  map.cameraIdle((lat: camera.center.latitude, lng: camera.center.longitude)),
            ),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.clicksos.app',
              ),
              riskHeatLayer(map.regions),
              if (map.myPosition case final me?)
                fm.MarkerLayer(
                  markers: [
                    fm.Marker(
                      key: const ValueKey('minha-posicao'),
                      point: _latLng(me),
                      width: 20,
                      height: 20,
                      child: const IgnorePointer(child: _MyLocationDot()),
                    ),
                  ],
                ),
              fm.MarkerLayer(markers: buildAlertMarkers(map.alerts, onTap: map.selectAlert)),
              const fm.SimpleAttributionWidget(
                source: Text('OpenStreetMap'),
                alignment: Alignment.bottomLeft,
              ),
            ],
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

class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4)],
        ),
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
