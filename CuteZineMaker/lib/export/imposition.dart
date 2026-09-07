import '../models/models.dart';

/// Classic one-sheet mini-zine fold on landscape US Letter (11 × 8.5 in).
///
/// Each cell is exactly [ZinePageSize] (2.75 × 4.25 in). Four across and
/// two down fill the sheet with no rescale:
///
/// ```
/// Landscape Letter
/// ┌────────┬────────┬────────┬────────┐
/// │  7 °   │  6 °   │  5 °   │  4 °   │  top half, each page 180°
/// ├────────┼────────┼────────┼────────┤
/// │   8    │   1    │   2    │   3    │  bottom half, right-side-up
/// └────────┴────────┴────────┴────────┘
/// ```
///
/// After print → fold in half / quarters → slit the center → nest into a
/// booklet, page 1 is the cover and the book reads 1–8. Top row is reversed
/// (7-6-5-4) so those pages land right-reading after the 180° rotation.
/// Zines that are not a multiple of 8 are **blank-padded** to the next
/// group of 8 (one Letter sheet per signature).
class FoldCell {
  const FoldCell({
    required this.signatureIndex,
    required this.column,
    required this.row,
    required this.rotated180,
  });

  /// 0-based page within an 8-page signature (0 = page 1).
  final int signatureIndex;

  /// 0 = left … 3 = right.
  final int column;

  /// 0 = top half, 1 = bottom half.
  final int row;
  final bool rotated180;
}

const foldCells = <FoldCell>[
  FoldCell(signatureIndex: 6, column: 0, row: 0, rotated180: true),
  FoldCell(signatureIndex: 5, column: 1, row: 0, rotated180: true),
  FoldCell(signatureIndex: 4, column: 2, row: 0, rotated180: true),
  FoldCell(signatureIndex: 3, column: 3, row: 0, rotated180: true),
  FoldCell(signatureIndex: 7, column: 0, row: 1, rotated180: false),
  FoldCell(signatureIndex: 0, column: 1, row: 1, rotated180: false),
  FoldCell(signatureIndex: 1, column: 2, row: 1, rotated180: false),
  FoldCell(signatureIndex: 2, column: 3, row: 1, rotated180: false),
];

int foldSignatureCount(int pageCount) {
  final n = pageCount < 1 ? 1 : pageCount;
  return (n + 7) ~/ 8;
}

/// Pads with blank cream pages so length is a multiple of 8.
List<ZinePage> paddedPagesForFold(List<ZinePage> pages) {
  final count = foldSignatureCount(pages.length) * 8;
  return [
    ...pages,
    for (var i = pages.length; i < count; i++) ZinePage.blank(),
  ];
}
