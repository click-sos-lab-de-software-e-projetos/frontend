import 'package:alerta_seguro/data/models/region_feedback.dart';
import 'package:alerta_seguro/data/models/risk_region.dart';
import 'package:alerta_seguro/data/repositories/region_repository.dart';
import 'package:alerta_seguro/data/repositories/repository_exception.dart';
import 'package:alerta_seguro/features/map/widgets/feedback_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _se = RiskRegion(
  id: 'se',
  name: 'Sé',
  center: (lat: 0, lng: 0),
  score: 80,
  color: Color(0xFFEF4444),
  radiusMeters: 1,
);

class _FailingFeedback extends FakeRegionRepository {
  @override
  Future<void> sendFeedback(String regionId, RegionFeedback feedback) =>
      Future.error(const RepositoryException('Região não encontrada.'));
}

/// Opens the sheet from a button and keeps what it returned.
Future<List<bool>> _open(WidgetTester tester, {FakeRegionRepository? regions}) async {
  final results = <bool>[];
  await pumpTestApp(
    tester,
    deps: TestDeps(loggedIn: true, regions: regions),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(await showFeedbackSheet(context, _se)),
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return results;
}

Finder get _send => find.widgetWithText(FilledButton, 'Enviar');

void main() {
  testWidgets('shows the district and the pending notice; send needs a category', (tester) async {
    await _open(tester);

    expect(find.textContaining('Sé'), findsWidgets);
    expect(find.text(FeedbackSheet.pendingNotice), findsOneWidget);
    expect(tester.widget<FilledButton>(_send).onPressed, isNull);
  });

  testWidgets('"Outro" without text shows the error and does not send', (tester) async {
    final regions = FakeRegionRepository();
    await _open(tester, regions: regions);

    await tester.tap(find.text('Outro'));
    await tester.pump();
    await tester.tap(_send);
    await tester.pump();

    expect(find.text(RegionFeedback.otherNeedsText), findsOneWidget);
    expect(regions.feedbacks, isEmpty);
  });

  testWidgets('sends the category and text for the region and closes', (tester) async {
    final regions = FakeRegionRepository();
    final results = await _open(tester, regions: regions);

    await tester.tap(find.text('Iluminação'));
    await tester.enterText(find.byType(TextField), 'Rua escura');
    await tester.pump();
    await tester.tap(_send);
    await tester.pumpAndSettle();

    expect(regions.feedbacks, [
      (regionId: 'se', feedback: const RegionFeedback(FeedbackCategory.lighting, 'Rua escura')),
    ]);
    expect(results, [true]);
    expect(find.text(FeedbackSheet.pendingNotice), findsNothing);
  });

  testWidgets('a failure keeps the sheet open with the message', (tester) async {
    final results = await _open(tester, regions: _FailingFeedback());

    await tester.tap(find.text('Assalto'));
    await tester.pump();
    await tester.tap(_send);
    await tester.pumpAndSettle();

    expect(find.text('Região não encontrada.'), findsOneWidget);
    expect(find.text(FeedbackSheet.pendingNotice), findsOneWidget);
    expect(results, isEmpty);
  });
}
