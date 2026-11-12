import 'package:click_sos/core/services/location_service.dart';
import 'package:click_sos/data/models/community_alert.dart';
import 'package:click_sos/data/models/risk_region.dart';
import 'package:click_sos/data/repositories/region_repository.dart';
import 'package:click_sos/data/repositories/repository_exception.dart';
import 'package:click_sos/features/auth/login_screen.dart';
import 'package:click_sos/features/map/map_controller.dart';
import 'package:click_sos/features/map/map_screen.dart';
import 'package:click_sos/features/map/widgets/alert_card.dart';
import 'package:click_sos/features/map/widgets/alert_markers.dart';
import 'package:click_sos/features/map/widgets/alert_sheet.dart';
import 'package:click_sos/features/map/widgets/region_card.dart';
import 'package:click_sos/features/map/widgets/region_heatmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide MapController;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

const _screen = MapScreen();

Finder get _alertButton => find.byTooltip('Criar alerta');

void _tapMap(WidgetTester tester, LatLng point) =>
    tester.widget<FlutterMap>(find.byType(FlutterMap)).options.onTap!(const TapPosition(Offset.zero, null), point);

void _tapRegion(WidgetTester tester, RiskRegion region) =>
    _tapMap(tester, LatLng(region.center.lat, region.center.lng));

RiskHeatTiles? _heat(WidgetTester tester) {
  for (final layer in tester.widgetList<TileLayer>(find.byType(TileLayer))) {
    if (layer.tileProvider case final RiskHeatTiles heat) return heat;
  }
  return null;
}

List<Marker> _markers(WidgetTester tester) => [
      for (final layer in tester.widgetList<MarkerLayer>(find.byType(MarkerLayer)))
        ...layer.markers.where((m) => m.key.toString().contains('alerta-')),
    ];

Finder get _myLocation => find.byKey(const ValueKey('minha-posicao'));

/// Fails until [failing] is turned off.
class _FlakyRegions extends FakeRegionRepository {
  bool failing = true;

  @override
  Future<List<RiskRegion>> fetchNearby({required double lat, required double lng, int radiusMeters = 0}) =>
      failing ? Future.error(const RepositoryException('Sem internet.')) : super.fetchNearby(lat: lat, lng: lng);
}

Future<TestDeps> _pump(WidgetTester tester, TestDeps deps) async {
  await pumpTestApp(tester, home: _screen, deps: deps);
  await tester.pumpAndSettle();
  return deps;
}

void main() {
  testWidgets('logged out still draws the regions', (tester) async {
    final deps = await _pump(tester, TestDeps());

    expect(_heat(tester), isNotNull);
    expect(deps.regions.requests, hasLength(1));
  });

  testWidgets('logged out, the alert button opens the login instead of the sheet', (tester) async {
    final deps = await _pump(tester, TestDeps());

    await tester.tap(_alertButton);
    await tester.pumpAndSettle();

    expect(find.text(MapScreen.loginToAlert), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AlertSheet), findsNothing);
    expect(deps.regions.created, isEmpty);
  });

  testWidgets('draws the regions as one heat layer over the base map, without legend', (tester) async {
    await _pump(tester, TestDeps(loggedIn: true));
    final regions = tester.element(find.byType(MapScreen)).read<MapController>().regions;

    expect(_heat(tester)!.regions, regions);
    expect(find.byType(TileLayer), findsNWidgets(2));
    expect(find.text('Alto'), findsNothing);
  });

  testWidgets('tapping a district shows the district, score and band', (tester) async {
    await _pump(tester, TestDeps(loggedIn: true));
    final region = tester.element(find.byType(MapScreen)).read<MapController>().regions.first;

    _tapRegion(tester, region);
    await tester.pump();

    expect(find.text(region.name), findsOneWidget);
    expect(find.text(RegionCard.summary(region)), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pump();
    expect(find.text(region.name), findsNothing);

    _tapRegion(tester, region);
    await tester.pump();
    _tapMap(tester, const LatLng(60, 60));
    await tester.pump();
    expect(find.text(region.name), findsNothing);
  });

  testWidgets('a failure shows the message and "Tentar de novo" loads again', (tester) async {
    final flaky = _FlakyRegions();
    await _pump(tester, TestDeps(loggedIn: true, regions: flaky));
    expect(find.text('Sem internet.'), findsOneWidget);

    flaky.failing = false;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Sem internet.'), findsNothing);
    expect(_heat(tester)!.regions, isNotEmpty);
  });

  testWidgets('shows my location only with permission already granted', (tester) async {
    await _pump(
      tester,
      TestDeps(loggedIn: true, location: FakeLocationService((lat: 1, lng: 2))..access = LocationAccess.denied),
    );

    expect(_myLocation, findsNothing);
  });

  testWidgets('shows my location when permission was already granted', (tester) async {
    await _pump(tester, TestDeps(loggedIn: true, location: FakeLocationService((lat: 1, lng: 2))));

    expect(_myLocation, findsOneWidget);
  });

  testWidgets('the alert button creates an alert at my position and pins it on the map', (tester) async {
    final deps = await _pump(tester, TestDeps(loggedIn: true, location: FakeLocationService((lat: 1, lng: 2))));
    final heatBefore = _heat(tester);
    expect(_markers(tester), isEmpty);

    await tester.tap(_alertButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assalto'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Alertar aqui'));
    await tester.pumpAndSettle();

    expect(deps.regions.created, [const NewAlert(AlertCategory.robbery, (lat: 1, lng: 2))]);
    expect(find.text(MapScreen.created), findsOneWidget);
    final marker = _markers(tester).single;
    expect(marker.point, const LatLng(1, 2));
    expect(_heat(tester)!.regions, same(heatBefore!.regions));

    await tester.tap(find.byType(AlertPin));
    await tester.pump();
    expect(find.byType(AlertCard), findsOneWidget);
    expect(find.text('Assalto'), findsOneWidget);
    expect(find.textContaining('agora'), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pump();
    expect(find.byType(AlertCard), findsNothing);
  });

  testWidgets('without location the alert button explains and opens no sheet', (tester) async {
    final deps = await _pump(
      tester,
      TestDeps(
        loggedIn: true,
        location: FakeLocationService((lat: 1, lng: 2))
          ..access = LocationAccess.denied
          ..afterRequest = LocationAccess.denied,
      ),
    );

    await tester.tap(_alertButton);
    await tester.pumpAndSettle();

    expect(find.text(MapScreen.needsLocation), findsOneWidget);
    expect(find.byType(AlertSheet), findsNothing);
    expect(deps.regions.created, isEmpty);
  });

  testWidgets('shows the alerts of the area as markers', (tester) async {
    final regions = FakeRegionRepository()
      ..alerts.add(
        CommunityAlert(
          id: 'a1',
          category: AlertCategory.harassment,
          text: 'Cuidado na saída do metrô',
          position: (lat: -23.55, lng: -46.63),
          createdAt: DateTime.now(),
        ),
      );
    await _pump(tester, TestDeps(regions: regions));

    expect(_markers(tester).single.key, const ValueKey('alerta-a1'));
    await tester.tap(find.byType(AlertPin));
    await tester.pump();
    expect(find.text('Cuidado na saída do metrô'), findsOneWidget);
  });
}
