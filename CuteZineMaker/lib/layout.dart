import 'dart:ui';

/// Editor chrome breakpoints.
///
/// - **Narrow** (phones, skinny browser): tools stay in a **bottom tray**.
/// - **Wide** (desktop web, large windows): tools live in a **collapsible
///   side menu**.
///
/// Wide when the shortest side is ≥ 600 logical px **or** width ≥ 840.
/// Resizing a browser window rebuilds via [MediaQuery] / [LayoutBuilder]
/// so the chrome swaps live.
abstract final class EditorLayout {
  static const double shortestSideBreakpoint = 600;
  static const double widthBreakpoint = 840;

  static bool isWide(Size size) =>
      size.shortestSide >= shortestSideBreakpoint ||
      size.width >= widthBreakpoint;
}
