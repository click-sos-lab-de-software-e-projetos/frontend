import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/data/models/community_alert.dart';
import 'package:alerta_seguro/data/models/risk_region.dart';
import 'package:alerta_seguro/data/repositories/region_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/auth/login_screen.dart';
import 'package:alerta_seguro/features/map/map_controller.dart';
import 'package:alerta_seguro/features/map/map_screen.dart';
import 'package:alerta_seguro/features/map/widgets/alert_card.dart';
import 'package:alerta_seguro/features/map/widgets/alert_sheet.dart';
import 'package:alerta_seguro/features/map/widgets/region_card.dart';
import 'package:alerta_seguro/features/map/widgets/region_heatmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

const _screen = MapScreen();

Finder get _alertButton => find.byTooltip('Criar alerta');

GoogleMap _googleMap(WidgetTester tester) => tester.widget<GoogleMap>(find.byType(GoogleMap));

void _tapRegion(WidgetTester tester, RiskRegion region) =>
    _googleMap(tester).onTap!(LatLng(region.center.lat, region.center.lng));

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

    expect(_googleMap(tester).tileOverlays, isNotEmpty);
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

  testWidgets('draws the regions as one heat overlay, without circles or legend', (tester) async {
    await _pump(tester, TestDeps(loggedIn: true));
    final regions = tester.element(find.byType(MapScreen)).read<MapController>().regions;

    final heat = _googleMap(tester).tileOverlays.single.tileProvider! as RiskHeatTiles;
    expect(heat.regions, regions);
    expect(_googleMap(tester).circles, isEmpty);
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
    _googleMap(tester).onTap!(const LatLng(60, 60));
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
    expect(_googleMap(tester).tileOverlays, isNotEmpty);
  });

  testWidgets('shows my location only with permission already granted', (tester) async {
    await _pump(
      tester,
      TestDeps(loggedIn: true, location: FakeLocationService((lat: 1, lng: 2))..access = LocationAccess.denied),
    );

    expect(_googleMap(tester).myLocationEnabled, isFalse);
  });

  testWidgets('the alert button creates an alert at my position and pins it on the map', (tester) async {
    final deps = await _pump(tester, TestDeps(loggedIn: true, location: FakeLocationService((lat: 1, lng: 2))));
    final heatBefore = _googleMap(tester).tileOverlays;
    expect(_googleMap(tester).markers, isEmpty);

    await tester.tap(_alertButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assalto'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Alertar aqui'));
    await tester.pumpAndSettle();

    expect(deps.regions.created, [const NewAlert(AlertCategory.robbery, (lat: 1, lng: 2))]);
    expect(find.text(MapScreen.created), findsOneWidget);
    final marker = _googleMap(tester).markers.single;
    expect(marker.position, const LatLng(1, 2));
    expect(_googleMap(tester).tileOverlays, heatBefore);

    marker.onTap!();
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
          position: (lat: 3, lng: 4),
          createdAt: DateTime.now(),
        ),
      );
    await _pump(tester, TestDeps(regions: regions));

    final marker = _googleMap(tester).markers.single;
    expect(marker.markerId, const MarkerId('a1'));
    marker.onTap!();
    await tester.pump();
    expect(find.text('Cuidado na saída do metrô'), findsOneWidget);
  });
}
