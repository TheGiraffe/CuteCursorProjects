import 'dart:math';
import 'dart:ui' show Color, Offset;

import 'page_size.dart';

export 'page_size.dart';

String newId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final r = Random().nextInt(0x7fffffff);
  return '${now.toRadixString(16)}${r.toRadixString(16)}';
}

int colorToArgb(Color color) => color.toARGB32();

Color colorFromArgb(int argb) => Color(argb);

/// Pen tool settings for the current stroke.
class PenSettings {
  PenSettings({
    this.color = const Color(0xFFE88AA8),
    this.thickness = 10,
    this.opacity = 1,
    this.sparkle = 0,
  });

  Color color;
  double thickness;
  double opacity;

  /// 0 = matte ink, 1 = fully glittered. Sparkle is baked along the path
  /// (deterministic dots / stars), not a live particle system.
  double sparkle;

  PenSettings copy() => PenSettings(
        color: color,
        thickness: thickness,
        opacity: opacity,
        sparkle: sparkle,
      );

  Map<String, dynamic> toJson() => {
        'color': colorToArgb(color),
        'thickness': thickness,
        'opacity': opacity,
        'sparkle': sparkle,
      };

  factory PenSettings.fromJson(Map<String, dynamic> json) => PenSettings(
        color: colorFromArgb(json['color'] as int? ?? 0xFFE88AA8),
        thickness: (json['thickness'] as num?)?.toDouble() ?? 10,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
        sparkle: (json['sparkle'] as num?)?.toDouble() ?? 0,
      );
}

enum BackgroundPattern {
  solid,
  hearts,
  palaka,
  waves,
  dots,
  stars,
  gingham,
}

class PageBackground {
  PageBackground({
    this.color = const Color(0xFFFFF6EE),
    this.pattern = BackgroundPattern.solid,
    this.patternColor,
  });

  Color color;
  BackgroundPattern pattern;
  Color? patternColor;

  PageBackground copy() => PageBackground(
        color: color,
        pattern: pattern,
        patternColor: patternColor,
      );

  Map<String, dynamic> toJson() => {
        'color': colorToArgb(color),
        'pattern': pattern.name,
        if (patternColor != null) 'patternColor': colorToArgb(patternColor!),
      };

  factory PageBackground.fromJson(Map<String, dynamic> json) {
    final name = json['pattern'] as String? ?? 'solid';
    return PageBackground(
      color: colorFromArgb(json['color'] as int? ?? 0xFFFFF6EE),
      pattern: BackgroundPattern.values.firstWhere(
        (p) => p.name == name,
        orElse: () => BackgroundPattern.solid,
      ),
      patternColor: json['patternColor'] == null
          ? null
          : colorFromArgb(json['patternColor'] as int),
    );
  }
}

class StrokePoint {
  const StrokePoint(this.x, this.y);

  final double x;
  final double y;

  Offset get offset => Offset(x, y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory StrokePoint.fromJson(Map<String, dynamic> json) => StrokePoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );
}

/// Freehand ink. Stored as point data so it stays editable after reload.
class Stroke {
  Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.thickness,
    required this.opacity,
    required this.sparkle,
  });

  final String id;
  final List<StrokePoint> points;
  Color color;
  double thickness;
  double opacity;
  double sparkle;

  Stroke copy() => Stroke(
        id: id,
        points: List<StrokePoint>.from(points),
        color: color,
        thickness: thickness,
        opacity: opacity,
        sparkle: sparkle,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'color': colorToArgb(color),
        'thickness': thickness,
        'opacity': opacity,
        'sparkle': sparkle,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        id: json['id'] as String,
        points: (json['points'] as List<dynamic>)
            .map((e) => StrokePoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        color: colorFromArgb(json['color'] as int),
        thickness: (json['thickness'] as num).toDouble(),
        opacity: (json['opacity'] as num).toDouble(),
        sparkle: (json['sparkle'] as num?)?.toDouble() ?? 0,
      );
}

enum OverlayKind { sticker, text }

/// Stickers and text share a z-order above ink.
abstract class OverlayItem {
  OverlayItem({
    required this.id,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.zIndex,
  });

  final String id;
  double x;
  double y;
  double scale;
  double rotation;
  int zIndex;

  OverlayKind get kind;

  OverlayItem copy();

  Map<String, dynamic> toJson();
}

class StickerInstance extends OverlayItem {
  StickerInstance({
    required super.id,
    required this.catalogId,
    required super.x,
    required super.y,
    super.scale = 1,
    super.rotation = 0,
    required super.zIndex,
  });

  String catalogId;

  @override
  OverlayKind get kind => OverlayKind.sticker;

  @override
  StickerInstance copy() => StickerInstance(
        id: id,
        catalogId: catalogId,
        x: x,
        y: y,
        scale: scale,
        rotation: rotation,
        zIndex: zIndex,
      );

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'id': id,
        'catalogId': catalogId,
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
        'zIndex': zIndex,
      };

  factory StickerInstance.fromJson(Map<String, dynamic> json) =>
      StickerInstance(
        id: json['id'] as String,
        catalogId: json['catalogId'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        scale: (json['scale'] as num?)?.toDouble() ?? 1,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        zIndex: json['zIndex'] as int? ?? 0,
      );
}

class TextBoxItem extends OverlayItem {
  TextBoxItem({
    required super.id,
    required this.text,
    required super.x,
    required super.y,
    super.scale = 1,
    super.rotation = 0,
    required super.zIndex,
    this.color = const Color(0xFF5A3E4A),
    this.fontSize = 36,
  });

  String text;
  Color color;
  double fontSize;

  @override
  OverlayKind get kind => OverlayKind.text;

  @override
  TextBoxItem copy() => TextBoxItem(
        id: id,
        text: text,
        x: x,
        y: y,
        scale: scale,
        rotation: rotation,
        zIndex: zIndex,
        color: color,
        fontSize: fontSize,
      );

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'id': id,
        'text': text,
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
        'zIndex': zIndex,
        'color': colorToArgb(color),
        'fontSize': fontSize,
      };

  factory TextBoxItem.fromJson(Map<String, dynamic> json) => TextBoxItem(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        scale: (json['scale'] as num?)?.toDouble() ?? 1,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        zIndex: json['zIndex'] as int? ?? 0,
        color: colorFromArgb(json['color'] as int? ?? 0xFF5A3E4A),
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 36,
      );
}

OverlayItem overlayFromJson(Map<String, dynamic> json) {
  final kind = json['kind'] as String? ?? 'sticker';
  if (kind == OverlayKind.text.name) {
    return TextBoxItem.fromJson(json);
  }
  return StickerInstance.fromJson(json);
}

class ZinePage {
  ZinePage({
    required this.id,
    PageBackground? background,
    List<Stroke>? strokes,
    List<OverlayItem>? overlays,
  })  : background = background ?? PageBackground(),
        strokes = strokes ?? <Stroke>[],
        overlays = overlays ?? <OverlayItem>[];

  final String id;
  PageBackground background;

  /// Ink layer — painted as one CustomPaint, never as a widget per stroke.
  final List<Stroke> strokes;

  /// Stickers and text, mutually reorderable, always above ink.
  final List<OverlayItem> overlays;

  List<OverlayItem> get overlaysByZ {
    final copy = List<OverlayItem>.from(overlays);
    copy.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return copy;
  }

  int nextZIndex() {
    var maxZ = 0;
    for (final item in overlays) {
      if (item.zIndex > maxZ) maxZ = item.zIndex;
    }
    return maxZ + 1;
  }

  OverlayItem? overlayById(String id) {
    for (final item in overlays) {
      if (item.id == id) return item;
    }
    return null;
  }

  ZinePage copy() => ZinePage(
        id: id,
        background: background.copy(),
        strokes: strokes.map((s) => s.copy()).toList(),
        overlays: overlays.map((o) => o.copy()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'background': background.toJson(),
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'overlays': overlays.map((o) => o.toJson()).toList(),
      };

  factory ZinePage.fromJson(Map<String, dynamic> json) => ZinePage(
        id: json['id'] as String,
        background: PageBackground.fromJson(
          json['background'] as Map<String, dynamic>? ?? {},
        ),
        strokes: (json['strokes'] as List<dynamic>? ?? [])
            .map((e) => Stroke.fromJson(e as Map<String, dynamic>))
            .toList(),
        overlays: (json['overlays'] as List<dynamic>? ?? [])
            .map((e) => overlayFromJson(e as Map<String, dynamic>))
            .toList(),
      );

  factory ZinePage.blank({Color? color}) => ZinePage(
        id: newId(),
        background: PageBackground(color: color ?? const Color(0xFFFFF6EE)),
      );
}

class Zine {
  static const schemaVersion = 1;

  Zine({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
  });

  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<ZinePage> pages;

  ZinePage pageById(String id) => pages.firstWhere((p) => p.id == id);

  Zine copy() => Zine(
        id: id,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        pages: pages.map((p) => p.copy()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pageWidthInches': ZinePageSize.widthInches,
        'pageHeightInches': ZinePageSize.heightInches,
        'dpi': ZinePageSize.dpi,
        'pages': pages.map((p) => p.toJson()).toList(),
      };

  factory Zine.fromJson(Map<String, dynamic> json) => Zine(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled zine',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        pages: (json['pages'] as List<dynamic>? ?? [])
            .map((e) => ZinePage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  factory Zine.create({
    String title = 'Untitled zine',
    int pageCount = ZinePageSize.defaultPageCount,
  }) {
    final now = DateTime.now();
    const papers = <Color>[
      Color(0xFFFFF6EE),
      Color(0xFFFFF0F4),
      Color(0xFFF4FFF8),
      Color(0xFFF4F4FF),
      Color(0xFFFFF8E8),
    ];
    final pages = <ZinePage>[
      for (var i = 0; i < pageCount.clamp(1, 32); i++)
        ZinePage.blank(color: papers[i % papers.length]),
    ];
    return Zine(
      id: newId(),
      title: title,
      createdAt: now,
      updatedAt: now,
      pages: pages,
    );
  }
}

class ZineSummary {
  ZineSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.pageCount,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final int pageCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'pageCount': pageCount,
      };

  factory ZineSummary.fromJson(Map<String, dynamic> json) => ZineSummary(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled zine',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        pageCount: json['pageCount'] as int? ?? 0,
      );

  factory ZineSummary.fromZine(Zine zine) => ZineSummary(
        id: zine.id,
        title: zine.title,
        updatedAt: zine.updatedAt,
        pageCount: zine.pages.length,
      );
}
