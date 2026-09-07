import 'dart:math';
import 'dart:ui';

import '../models/models.dart';

Path smoothStrokePath(List<StrokePoint> points) {
  final path = Path();
  if (points.isEmpty) return path;
  path.moveTo(points.first.x, points.first.y);
  if (points.length == 1) {
    path.addOval(
      Rect.fromCircle(center: points.first.offset, radius: 0.4),
    );
    return path;
  }
  for (var i = 0; i < points.length - 1; i++) {
    final p0 = points[i];
    final p1 = points[i + 1];
    final mid = Offset((p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
    path.quadraticBezierTo(p0.x, p0.y, mid.dx, mid.dy);
  }
  path.lineTo(points.last.x, points.last.y);
  return path;
}

double polylineLength(List<StrokePoint> points) {
  var len = 0.0;
  for (var i = 1; i < points.length; i++) {
    len += (points[i].offset - points[i - 1].offset).distance;
  }
  return len;
}

/// Deterministic 0..1 from two ints — sparkle must look identical on
/// canvas, thumbnail, and PDF raster.
double hash01(int a, int b) {
  var n = (a * 73856093) ^ (b * 19349663);
  n = (n * 1103515245 + 12345) & 0x7fffffff;
  return n / 0x7fffffff;
}

int mixHash(int a, int b) => (a * 16777619) ^ b;

Path heartPath(Offset center, double size) {
  final path = Path();
  final s = size;
  path.moveTo(center.dx, center.dy + s * 0.32);
  path.cubicTo(
    center.dx - s * 0.95,
    center.dy - s * 0.15,
    center.dx - s * 0.45,
    center.dy - s * 0.85,
    center.dx,
    center.dy - s * 0.32,
  );
  path.cubicTo(
    center.dx + s * 0.45,
    center.dy - s * 0.85,
    center.dx + s * 0.95,
    center.dy - s * 0.15,
    center.dx,
    center.dy + s * 0.32,
  );
  path.close();
  return path;
}

Path starPath(Offset center, double radius, {int points = 5}) {
  final path = Path();
  final inner = radius * 0.42;
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? radius : inner;
    final a = -pi / 2 + i * pi / points;
    final p = Offset(center.dx + cos(a) * r, center.dy + sin(a) * r);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  return path;
}

/// dart:ui [Gradient] throws if [colors] is not length 2 and [colorStops]
/// is omitted. Widget [LinearGradient] is fine; these helpers are for
/// [Paint.shader] on the scene-graph canvas.
Shader linearShader(Offset from, Offset to, List<Color> colors) {
  final pair = _gradientColors(colors);
  if (pair.length == 2) {
    return Gradient.linear(from, to, pair);
  }
  return Gradient.linear(from, to, pair, _evenStops(pair.length));
}

Shader radialShader(Offset center, double radius, List<Color> colors) {
  final pair = _gradientColors(colors);
  if (pair.length == 2) {
    return Gradient.radial(center, radius, pair);
  }
  return Gradient.radial(center, radius, pair, _evenStops(pair.length));
}

List<Color> _gradientColors(List<Color> colors) {
  if (colors.isEmpty) {
    return const [Color(0x00000000), Color(0x00000000)];
  }
  if (colors.length == 1) {
    return [colors.first, colors.first];
  }
  return colors;
}

List<double> _evenStops(int n) =>
    List<double>.generate(n, (i) => i / (n - 1));

Path diamondPath(Offset center, double w, double h) {
  return Path()
    ..moveTo(center.dx, center.dy - h / 2)
    ..lineTo(center.dx + w / 2, center.dy)
    ..lineTo(center.dx, center.dy + h / 2)
    ..lineTo(center.dx - w / 2, center.dy)
    ..close();
}

/// Baked glitter along a stroke. Same algorithm for screen and export.
void paintBakedSparkle(Canvas canvas, Stroke stroke) {
  if (stroke.sparkle <= 0.01 || stroke.points.isEmpty) return;
  final seed = stroke.id.hashCode;
  final spacing = max(5.0, (10.0 + stroke.thickness * 0.35) / (0.4 + stroke.sparkle));
  final colors = <Color>[
    const Color(0xFFFFF4C2),
    const Color(0xFFFFC6E0),
    const Color(0xFFC8F4E0),
    const Color(0xFFE4D4FF),
    const Color(0xFFFFFFFF),
    const Color(0xFFFFD4A8),
  ];

  void speck(Offset at, int i) {
    final h = hash01(seed, i);
    final h2 = hash01(seed, i + 97);
    final h3 = hash01(seed, i + 191);
    final jitter = Offset((h - 0.5) * stroke.thickness * 1.6, (h2 - 0.5) * stroke.thickness * 1.6);
    final p = at + jitter;
    final size = (1.4 + h3 * 3.2) * (0.6 + stroke.sparkle) * (0.55 + stroke.thickness / 22);
    final color = colors[i % colors.length].withValues(alpha: 0.55 + h * 0.4);
    final paint = Paint()..color = color;
    final kind = (mixHash(seed, i) % 3);
    if (kind == 0) {
      canvas.drawCircle(p, size, paint);
    } else if (kind == 1) {
      canvas.drawPath(diamondPath(p, size * 1.7, size * 2.4), paint);
    } else {
      canvas.drawPath(starPath(p, size * 1.5, points: 4), paint);
    }
  }

  if (stroke.points.length == 1) {
    speck(stroke.points.first.offset, 0);
    return;
  }

  var i = 0;
  var carry = 0.0;
  for (var s = 1; s < stroke.points.length; s++) {
    final a = stroke.points[s - 1].offset;
    final b = stroke.points[s].offset;
    final seg = (b - a).distance;
    var d = carry;
    while (d <= seg) {
      final t = seg == 0 ? 0.0 : d / seg;
      speck(Offset.lerp(a, b, t)!, i++);
      d += spacing;
    }
    carry = d - seg;
  }
}
