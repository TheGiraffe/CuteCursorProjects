import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:petal_press/export/imposition.dart';
import 'package:petal_press/export/pdf_export.dart';
import 'package:petal_press/models/models.dart';

void main() {
  test('1-up PDF pages are exactly 2.75 × 4.25 inches', () {
    final format = zinePdfPageFormat();
    expect(format.width, closeTo(2.75 * PdfPageFormat.inch, 0.0001));
    expect(format.height, closeTo(4.25 * PdfPageFormat.inch, 0.0001));
    expect(format.width / PdfPageFormat.inch, ZinePageSize.widthInches);
    expect(format.height / PdfPageFormat.inch, ZinePageSize.heightInches);
  });

  test('fold PDF is landscape US Letter (11 × 8.5 in)', () {
    final format = foldLetterPageFormat();
    expect(format.width, closeTo(11 * PdfPageFormat.inch, 0.0001));
    expect(format.height, closeTo(8.5 * PdfPageFormat.inch, 0.0001));
    expect(format.width, 4 * zinePdfPageFormat().width);
    expect(format.height, 2 * zinePdfPageFormat().height);
  });

  test('imposition maps 8-1-2-3 under 7-6-5-4 rotated', () {
    expect(foldCells, hasLength(8));
    FoldCell at(int col, int row) =>
        foldCells.firstWhere((c) => c.column == col && c.row == row);

    expect(at(0, 0).signatureIndex, 6);
    expect(at(1, 0).signatureIndex, 5);
    expect(at(2, 0).signatureIndex, 4);
    expect(at(3, 0).signatureIndex, 3);
    expect(foldCells.where((c) => c.row == 0).every((c) => c.rotated180), isTrue);

    expect(at(0, 1).signatureIndex, 7);
    expect(at(1, 1).signatureIndex, 0);
    expect(at(2, 1).signatureIndex, 1);
    expect(at(3, 1).signatureIndex, 2);
    expect(foldCells.where((c) => c.row == 1).every((c) => !c.rotated180), isTrue);
  });

  test('fold mode pads to groups of 8 and counts signatures', () {
    expect(foldSignatureCount(1), 1);
    expect(foldSignatureCount(8), 1);
    expect(foldSignatureCount(9), 2);
    expect(paddedPagesForFold(Zine.create(pageCount: 3).pages), hasLength(8));
    expect(paddedPagesForFold(Zine.create(pageCount: 8).pages), hasLength(8));
    expect(paddedPagesForFold(Zine.create(pageCount: 10).pages), hasLength(16));
  });
}
