import 'package:alerta_seguro/core/services/location_service.dart';
import 'package:alerta_seguro/features/map/occurrences_controller.dart';
import 'package:alerta_seguro/features/occurrence/occurrence_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows validation errors and does not send an empty form', (tester) async {
    final deps = await pumpTestApp(tester, home: const OccurrenceScreen());

    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o endereço ou use a localização atual.'), findsOneWidget);
    expect(find.text('Informe a data e a hora.'), findsOneWidget);
    expect(find.text('Selecione o tipo de ocorrência.'), findsOneWidget);
    expect(deps.occurrences.reports, isEmpty);
  });

  testWidgets('a complete form sends an ISO-8601 report and plots it', (tester) async {
    final deps = await pumpTestApp(
      tester,
      deps: TestDeps(location: FakeLocationService((lat: -23.5, lng: -46.6))),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const OccurrenceScreen())),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usar localização atual'));
    await tester.pumpAndSettle();
    expect(find.text('Localização atual (-23.5000, -46.6000)'), findsOneWidget);

    // Time picker: accept the default (now).
    await tester.tap(find.text('00:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Date picker: accept the default (today).
    await tester.tap(find.text('DD/MM/AA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Selecionar opção...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assédio').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.byType(OccurrenceScreen), findsNothing);
    final report = deps.occurrences.reports.single;
    expect(report.type, 'Assédio');
    expect(report.lat, -23.5);
    expect(report.toJson()['datetime'], matches(RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$')));
    final plotted = tester.element(find.text('abrir')).read<OccurrencesController>().occurrences;
    expect(plotted.single.type, 'Assédio');
  });
}
