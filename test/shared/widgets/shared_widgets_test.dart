import 'package:alerta_seguro/app/theme.dart';
import 'package:alerta_seguro/shared/widgets/app_card.dart';
import 'package:alerta_seguro/shared/widgets/app_text_field.dart';
import 'package:alerta_seguro/shared/widgets/outline_action_button.dart';
import 'package:alerta_seguro/shared/widgets/page_header.dart';
import 'package:alerta_seguro/shared/widgets/section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(children: [child]))));

void main() {
  testWidgets('SectionLabel renders text in upper case', (tester) async {
    await pump(tester, const SectionLabel('Nome'));
    expect(find.text('NOME'), findsOneWidget);
  });

  testWidgets('AppCard renders its child, including ListTiles, without errors', (tester) async {
    await pump(tester, const AppCard(child: ListTile(title: Text('tile'))));
    expect(find.text('tile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppTextField shows hint, edits controller and can obscure', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await pump(tester, AppTextField('Senha', c, obscure: true));

    expect(find.text('Senha'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'abc');
    expect(c.text, 'abc');
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
  });

  testWidgets('PageHeader renders title and optional subtitle', (tester) async {
    await pump(tester, const PageHeader('Título', subtitle: 'Sub'));
    expect(find.text('Título'), findsOneWidget);
    expect(find.text('Sub'), findsOneWidget);

    await pump(tester, const PageHeader('Só título'));
    expect(find.text('Sub'), findsNothing);
  });

  testWidgets('OutlineActionButton calls onPressed and uses the given color', (tester) async {
    var taps = 0;
    await pump(tester, OutlineActionButton('Salvar', () => taps++, color: AppColors.red));

    await tester.tap(find.text('Salvar'));
    expect(taps, 1);
    final style = tester.widget<OutlinedButton>(find.byType(OutlinedButton)).style!;
    expect(style.foregroundColor!.resolve({}), AppColors.red);
  });
}
