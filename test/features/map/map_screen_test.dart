import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/data/models/risk_region.dart';
import 'package:alerta_seguro/data/repositories/region_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/auth/login_screen.dart';
import 'package:alerta_seguro/features/map/map_controller.dart';
import 'package:alerta_seguro/features/map/map_screen.dart';
import 'package:alerta_seguro/features/map/widgets/feedback_sheet.dart';
import 'package:alerta_seguro/features/map/widgets/region_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

const _screen = MapScreen();

GoogleMap _googleMap(WidgetTester tester) => tester.widget<GoogleMap>(find.byType(GoogleMap));

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

    expect(_googleMap(tester).circles, isNotEmpty);
    expect(deps.regions.requests, hasLength(1));
  });

  testWidgets('logged out, feedback opens the login instead of the sheet', (tester) async {
    final deps = await _pump(tester, TestDeps());
    final region = tester.element(find.byType(MapScreen)).read<MapController>().regions.first;

    _googleMap(tester).circles.firstWhere((c) => c.circleId.value == region.id).onTap!();
    await tester.pump();
    await tester.tap(find.text('Enviar feedback'));
    await tester.pumpAndSettle();

    expect(find.text(MapScreen.loginToFeedback), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(FeedbackSheet), findsNothing);
    expect(deps.regions.feedbacks, isEmpty);
  });

  testWidgets('logged in draws one circle per region with the API color and radius', (tester) async {
    await _pump(tester, TestDeps(loggedIn: true));
    final regions = tester.element(find.byType(MapScreen)).read<MapController>().regions;

    final circles = _googleMap(tester).circles;
    expect(circles, hasLength(regions.length));
    final first = circles.firstWhere((c) => c.circleId.value == regions.first.id);
    expect(first.radius, regions.first.radiusMeters);
    expect(first.fillColor.toARGB32() & 0xFFFFFF, regions.first.color.toARGB32() & 0xFFFFFF);
    expect(find.text('Alto'), findsOneWidget);
  });

  testWidgets('tapping a circle shows the district, score and band', (tester) async {
    await _pump(tester, TestDeps(loggedIn: true));
    final region = tester.element(find.byType(MapScreen)).read<MapController>().regions.first;

    _googleMap(tester).circles.firstWhere((c) => c.circleId.value == region.id).onTap!();
    await tester.pump();

    expect(find.text(region.name), findsOneWidget);
    expect(find.text(RegionCard.summary(region)), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar'));
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
    expect(_googleMap(tester).circles, isNotEmpty);
  });

  testWidgets('shows my location only with permission already granted', (tester) async {
    await _pump(
      tester,
      TestDeps(loggedIn: true, location: FakeLocationService((lat: 1, lng: 2))..access = LocationAccess.denied),
    );

    expect(_googleMap(tester).myLocationEnabled, isFalse);
  });

  testWidgets('feedback from the district card thanks and leaves the map unchanged', (tester) async {
    final deps = await _pump(tester, TestDeps(loggedIn: true));
    final region = tester.element(find.byType(MapScreen)).read<MapController>().regions.first;
    final circlesBefore = _googleMap(tester).circles;
    expect(find.text('Registrar ocorrência'), findsNothing);

    _googleMap(tester).circles.firstWhere((c) => c.circleId.value == region.id).onTap!();
    await tester.pump();
    await tester.tap(find.text('Enviar feedback'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iluminação'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    expect(deps.regions.feedbacks.single.regionId, region.id);
    expect(find.text(MapScreen.thanks), findsOneWidget);
    expect(find.text(FeedbackSheet.pendingNotice), findsNothing);
    expect(_googleMap(tester).circles, circlesBefore);
    expect(deps.regions.requests, hasLength(1));
  });
}
