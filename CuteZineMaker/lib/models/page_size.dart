/// Mini-zine page geometry.
///
/// A classic 8-page mini-zine is one US Letter sheet (8.5 × 11 in) folded into
/// eighths. One portrait panel is therefore **2.75 in × 4.25 in**.
///
/// These named constants are the single source of truth for the on-screen
/// canvas, persisted stroke coordinates, thumbnail raster, and 1-up PDF
/// export. Do not introduce a freeform or device-sized drawing surface.
///
/// Folded 8-up Letter export lives in `lib/export/imposition.dart`:
/// landscape 11 × 8.5 in, bottom **8 · 1 · 2 · 3**, top **7 · 6 · 5 · 4**
/// each rotated 180°. Flood-fill, cloud sharing, and discovery are still
/// deferred; they should keep using this page size.
abstract final class ZinePageSize {
  static const double widthInches = 2.75;
  static const double heightInches = 4.25;

  /// Raster / logical resolution. Stroke points are stored in this space
  /// so ink stays resolution-independent and re-editable.
  static const int dpi = 300;

  static const double logicalWidth = widthInches * dpi; // 825
  static const double logicalHeight = heightInches * dpi; // 1275

  static const double aspectRatio = widthInches / heightInches;

  static const int defaultPageCount = 8;
}
