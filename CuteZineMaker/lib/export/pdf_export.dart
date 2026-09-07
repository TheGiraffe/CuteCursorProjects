import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../render/zine_painter.dart';
import '../theme.dart';
import 'imposition.dart';

enum PdfExportLayout { singlePages, foldLetter }

/// 1-up PDF page format: one mini-zine page per PDF page.
PdfPageFormat zinePdfPageFormat() => PdfPageFormat(
      ZinePageSize.widthInches * PdfPageFormat.inch,
      ZinePageSize.heightInches * PdfPageFormat.inch,
      marginAll: 0,
    );

/// Landscape US Letter: 11 × 8.5 in (four 2.75 in columns × two 4.25 in rows).
PdfPageFormat foldLetterPageFormat() => PdfPageFormat(
      11 * PdfPageFormat.inch,
      8.5 * PdfPageFormat.inch,
      marginAll: 0,
    );

Future<Uint8List> exportZinePdf(
  Zine zine, {
  PdfExportLayout layout = PdfExportLayout.singlePages,
}) async {
  final doc = pw.Document(title: zine.title, author: AppDisplay.name);
  if (layout == PdfExportLayout.foldLetter) {
    await _addFoldSheets(doc, zine);
  } else {
    await _addSinglePages(doc, zine);
  }
  return doc.save();
}

Future<void> _addSinglePages(pw.Document doc, Zine zine) async {
  final format = zinePdfPageFormat();
  for (final page in zine.pages) {
    final pwImage = pw.MemoryImage(await _pngOf(page));
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.SizedBox.expand(
          child: pw.Image(pwImage, fit: pw.BoxFit.fill),
        ),
      ),
    );
  }
}

Future<void> _addFoldSheets(pw.Document doc, Zine zine) async {
  final padded = paddedPagesForFold(zine.pages);
  final format = foldLetterPageFormat();
  final cellW = ZinePageSize.widthInches * PdfPageFormat.inch;
  final cellH = ZinePageSize.heightInches * PdfPageFormat.inch;
  final signatures = foldSignatureCount(padded.length);

  for (var s = 0; s < signatures; s++) {
    final slice = padded.sublist(s * 8, s * 8 + 8);
    final images = <pw.MemoryImage>[];
    for (final page in slice) {
      images.add(pw.MemoryImage(await _pngOf(page)));
    }

    pw.Widget cell(FoldCell spec) {
      final img = pw.Image(images[spec.signatureIndex], fit: pw.BoxFit.fill);
      final child = spec.rotated180
          ? pw.Transform.rotate(angle: math.pi, child: img)
          : img;
      return pw.SizedBox(width: cellW, height: cellH, child: child);
    }

    final byRow = <int, List<FoldCell>>{};
    for (final spec in foldCells) {
      byRow.putIfAbsent(spec.row, () => []).add(spec);
    }
    for (final row in byRow.values) {
      row.sort((a, b) => a.column.compareTo(b.column));
    }

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Column(
          children: [
            pw.Row(children: [for (final spec in byRow[0]!) cell(spec)]),
            pw.Row(children: [for (final spec in byRow[1]!) cell(spec)]),
          ],
        ),
      ),
    );
  }
}

Future<Uint8List> _pngOf(ZinePage page) async {
  final image = await rasterizePage(page, scale: 1);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData!.buffer.asUint8List();
}

Future<void> shareZinePdf(
  Zine zine, {
  PdfExportLayout layout = PdfExportLayout.singlePages,
}) async {
  final bytes = await exportZinePdf(zine, layout: layout);
  final fold = layout == PdfExportLayout.foldLetter ? '_fold_letter' : '';
  final name =
      '${zine.title.replaceAll(RegExp(r"[^a-zA-Z0-9]+"), "_")}$fold.pdf';
  await Printing.sharePdf(bytes: bytes, filename: name);
}
