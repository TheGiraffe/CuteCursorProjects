import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_press/export/pdf_export.dart';
import 'package:petal_press/widgets/pdf_export_busy.dart';

void main() {
  test('busy copy matches layout', () {
    expect(
      pdfExportBusyMessage(PdfExportLayout.singlePages),
      'Printing pages…',
    );
    expect(
      pdfExportBusyMessage(PdfExportLayout.foldLetter),
      'Folding your zine…',
    );
  });

  testWidgets('fold busy card shows folding copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PdfExportBusyCard(layout: PdfExportLayout.foldLetter),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Folding your zine…'), findsOneWidget);
    expect(find.text('Hang tight — glitter takes a second.'), findsOneWidget);
  });
}
