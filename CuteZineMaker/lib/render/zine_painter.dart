import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/models.dart';
import 'background_painter.dart';
import 'draw_helpers.dart';
import 'sticker_catalog.dart';

/// Paints a full page from the scene graph: background → ink → overlays.
/// One [CustomPaint], never a widget per stroke.
class ZinePainter extends CustomPainter {
  ZinePainter({
    required this.page,
    this.activeStroke,
    this.selectedId,
    this.showSelection = true,
  });

  final ZinePage page;
  final Stroke? activeStroke;
  final String? selectedId;
  final bool showSelection;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / ZinePageSize.logicalWidth;
    final sy = size.height / ZinePageSize.logicalHeight;
    canvas.save();
    canvas.scale(sx, sy);
    paintLogical(canvas, const Size(ZinePageSize.logicalWidth, ZinePageSize.logicalHeight));
    canvas.restore();
  }

  void paintLogical(Canvas canvas, Size size) {
    paintPageBackground(canvas, size, page.background);
    for (final stroke in page.strokes) {
      paintStroke(canvas, stroke);
    }
    if (activeStroke != null) {
      paintStroke(canvas, activeStroke!);
    }
    for (final item in page.overlaysByZ) {
      paintOverlay(canvas, item);
      if (showSelection && item.id == selectedId) {
        _selection(canvas, item);
      }
    }
  }

  static void paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    final path = smoothStrokePath(stroke.points);
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: stroke.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
    paintBakedSparkle(canvas, stroke);
  }

  static void paintOverlay(Canvas canvas, OverlayItem item) {
    canvas.save();
    canvas.translate(item.x, item.y);
    canvas.rotate(item.rotation);
    canvas.scale(item.scale);
    if (item is StickerInstance) {
      final def = StickerCatalog.byId(item.catalogId);
      if (def != null) {
        canvas.translate(-def.size.width / 2, -def.size.height / 2);
        def.paint(canvas, def.size);
      }
    } else if (item is TextBoxItem) {
      final tp = TextPainter(
        text: TextSpan(
          text: item.text.isEmpty ? 'type…' : item.text,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: item.fontSize,
            color: item.text.isEmpty
                ? item.color.withValues(alpha: 0.35)
                : item.color,
            height: 1.1,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 360);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    }
    canvas.restore();
  }

  void _selection(Canvas canvas, OverlayItem item) {
    final box = overlayBounds(item);
    final r = RRect.fromRectAndRadius(box.inflate(10), const Radius.circular(10));
    canvas.drawRRect(
      r,
      Paint()
        ..color = const Color(0xFFB8D8F8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      Offset(box.center.dx, box.top - 18),
      7,
      Paint()..color = const Color(0xFFD9C6F0),
    );
  }

  static Rect overlayBounds(OverlayItem item) {
    Size raw = const Size(120, 120);
    if (item is StickerInstance) {
      raw = StickerCatalog.byId(item.catalogId)?.size ?? raw;
    } else if (item is TextBoxItem) {
      raw = Size(item.fontSize * max(2, item.text.length * 0.62), item.fontSize * 1.4);
    }
    final w = raw.width * item.scale;
    final h = raw.height * item.scale;
    return Rect.fromCenter(center: Offset(item.x, item.y), width: w, height: h);
  }

  static OverlayItem? hitTestOverlay(ZinePage page, Offset pagePoint) {
    for (final item in page.overlaysByZ.reversed) {
      if (_hit(item, pagePoint)) return item;
    }
    return null;
  }

  static bool _hit(OverlayItem item, Offset pagePoint) {
    final dx = pagePoint.dx - item.x;
    final dy = pagePoint.dy - item.y;
    final c = cos(-item.rotation);
    final s = sin(-item.rotation);
    final lx = (dx * c - dy * s) / item.scale;
    final ly = (dx * s + dy * c) / item.scale;
    Size raw = const Size(120, 120);
    if (item is StickerInstance) {
      raw = StickerCatalog.byId(item.catalogId)?.size ?? raw;
    } else if (item is TextBoxItem) {
      raw = Size(
        max(80, item.fontSize * max(2, item.text.length * 0.62)),
        item.fontSize * 1.6,
      );
    }
    return lx.abs() <= raw.width / 2 && ly.abs() <= raw.height / 2;
  }

  @override
  bool shouldRepaint(covariant ZinePainter oldDelegate) =>
      oldDelegate.page != page ||
      oldDelegate.activeStroke != activeStroke ||
      oldDelegate.selectedId != selectedId ||
      oldDelegate.showSelection != showSelection;
}

Future<ui.Image> rasterizePage(
  ZinePage page, {
  double scale = 1,
  Stroke? activeStroke,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final logical = const Size(ZinePageSize.logicalWidth, ZinePageSize.logicalHeight);
  canvas.scale(scale);
  ZinePainter(page: page, activeStroke: activeStroke, showSelection: false)
      .paintLogical(canvas, logical);
  final picture = recorder.endRecording();
  return picture.toImage(
    (ZinePageSize.logicalWidth * scale).round(),
    (ZinePageSize.logicalHeight * scale).round(),
  );
}

Future<Uint8List> rasterizePagePng(
  ZinePage page, {
  double scale = 0.28,
}) async {
  final image = await rasterizePage(page, scale: scale);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}
