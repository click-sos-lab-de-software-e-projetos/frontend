import 'package:click_sos/data/models/community_alert.dart';
import 'package:click_sos/data/repositories/region_repository.dart';
import 'package:click_sos/data/repositories/repository_exception.dart';
import 'package:click_sos/features/map/widgets/alert_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _here = (lat: -23.5, lng: -46.6);

class _FailingAlerts extends FakeRegionRepository {
  @override
  Future<CommunityAlert> createAlert(NewAlert alert) => Future.error(const RepositoryException('Sem conexão.'));
}

/// Opens the sheet from a button and keeps what it returned.
Future<List<CommunityAlert?>> _open(WidgetTester tester, {FakeRegionRepository? regions}) async {
  final results = <CommunityAlert?>[];
  await pumpTestApp(
    tester,
    deps: TestDeps(loggedIn: true, regions: regions),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(await showAlertSheet(context, _here)),
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return results;
}

Finder get _send => find.widgetWithText(FilledButton, 'Alertar aqui');

void main() {
  testWidgets('shows the 24 h notice; sending needs a category', (tester) async {
    await _open(tester);

    expect(find.text(AlertSheet.notice), findsOneWidget);
    expect(tester.widget<FilledButton>(_send).onPressed, isNull);
  });

  testWidgets('"Outro" without text shows the error and does not send', (tester) async {
    final regions = FakeRegionRepository();
    await _open(tester, regions: regions);

    await tester.tap(find.text('Outro'));
    await tester.pump();
    await tester.tap(_send);
    await tester.pump();

    expect(find.text(NewAlert.otherNeedsText), findsOneWidget);
    expect(regions.created, isEmpty);
  });

  testWidgets('creates the alert at the given position and returns it', (tester) async {
    final regions = FakeRegionRepository();
    final results = await _open(tester, regions: regions);

    await tester.tap(find.text('Iluminação'));
    await tester.enterText(find.byType(TextField), 'Rua escura');
    await tester.pump();
    await tester.tap(_send);
    await tester.pumpAndSettle();

    expect(regions.created, [const NewAlert(AlertCategory.lighting, _here, 'Rua escura')]);
    expect(results, [regions.alerts.single]);
    expect(find.text(AlertSheet.notice), findsNothing);
  });

  testWidgets('a failure keeps the sheet open with the message', (tester) async {
    final results = await _open(tester, regions: _FailingAlerts());

    await tester.tap(find.text('Assalto'));
    await tester.pump();
    await tester.tap(_send);
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão.'), findsOneWidget);
    expect(find.text(AlertSheet.notice), findsOneWidget);
    expect(results, isEmpty);
  });
}
