import 'dart:math';

import 'package:flutter/material.dart';

import 'draw_helpers.dart';

enum StickerCategory { letters, numbers, sparkle, gems, notions, faces }

class StickerDef {
  const StickerDef({
    required this.id,
    required this.name,
    required this.category,
    required this.size,
    required this.paint,
  });

  final String id;
  final String name;
  final StickerCategory category;
  final Size size;
  final void Function(Canvas canvas, Size size) paint;
}

/// Cute starter sticker library, drawn in code so PDF export matches screen.
abstract final class StickerCatalog {
  static final List<StickerDef> all = [
    ..._ransomGlyphs(),
    ..._sparkleShapes(),
    ..._gems(),
    ..._notions(),
    ..._faces(),
  ];

  static StickerDef? byId(String id) {
    for (final def in all) {
      if (def.id == id) return def;
    }
    return null;
  }

  static List<StickerDef> inCategory(StickerCategory category) =>
      all.where((s) => s.category == category).toList();
}

List<StickerDef> _ransomGlyphs() {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const digits = '0123456789';
  return [
    for (var i = 0; i < letters.length; i++)
      StickerDef(
        id: 'letter_${letters[i]}',
        name: letters[i],
        category: StickerCategory.letters,
        size: const Size(108, 124),
        paint: (c, s) => _ransom(c, s, letters[i], i),
      ),
    for (var i = 0; i < digits.length; i++)
      StickerDef(
        id: 'digit_$i',
        name: digits[i],
        category: StickerCategory.numbers,
        size: const Size(100, 118),
        paint: (c, s) => _ransom(c, s, digits[i], i + 26),
      ),
  ];
}

const _paperColors = <Color>[
  Color(0xFFFFF4C8),
  Color(0xFFFFD6E8),
  Color(0xFFD6F0FF),
  Color(0xFFE8D6FF),
  Color(0xFFD8F8E0),
  Color(0xFFFFE0C8),
  Color(0xFFFFF0F0),
  Color(0xFFE8F4D8),
];

const _inkColors = <Color>[
  Color(0xFF3A2A32),
  Color(0xFF7A3050),
  Color(0xFF2F4A6A),
  Color(0xFF3A5A3A),
  Color(0xFF6A3A20),
  Color(0xFF4A2A6A),
];

void _ransom(Canvas canvas, Size size, String ch, int variant) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final rot = (hash01(variant, 3) - 0.5) * 0.28;
  canvas.save();
  canvas.translate(cx, cy);
  canvas.rotate(rot);
  final paper = _paperColors[variant % _paperColors.length];
  final ink = _inkColors[variant % _inkColors.length];
  final w = size.width * 0.82;
  final h = size.height * 0.72;
  final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(6 + (variant % 5) * 2));
  canvas.drawRRect(
    rrect.shift(const Offset(3, 4)),
    Paint()..color = const Color(0x33000000),
  );
  final shape = variant % 4;
  final fill = Paint()..color = paper;
  if (shape == 0) {
    canvas.drawRRect(rrect, fill);
  } else if (shape == 1) {
    canvas.drawOval(rect.inflate(2), fill);
  } else if (shape == 2) {
    final p = Path()
      ..moveTo(rect.left + 4, rect.top + 8)
      ..lineTo(rect.right - 2, rect.top + 2)
      ..lineTo(rect.right - 6, rect.bottom - 3)
      ..lineTo(rect.left + 2, rect.bottom - 6)
      ..close();
    canvas.drawPath(p, fill);
  } else {
    canvas.drawRRect(rrect, fill);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, 10, rect.height),
      Paint()..color = const Color(0x66FFFFFF),
    );
  }
  canvas.drawRRect(
    rrect,
    Paint()
      ..color = const Color(0x22000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );
  final family = variant.isEven ? 'Fredoka' : 'Nunito';
  final tp = TextPainter(
    text: TextSpan(
      text: ch,
      style: TextStyle(
        fontFamily: family,
        fontSize: 62,
        fontWeight: variant % 3 == 0 ? FontWeight.w800 : FontWeight.w600,
        color: ink,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2 - 2));
  canvas.restore();
}

List<StickerDef> _sparkleShapes() {
  return [
    StickerDef(
      id: 'glitter_star',
      name: 'Glitter star',
      category: StickerCategory.sparkle,
      size: const Size(128, 128),
      paint: (c, s) => _glitterShape(c, s, _Shape.star, const Color(0xFFFFC6E8)),
    ),
    StickerDef(
      id: 'glitter_heart',
      name: 'Glitter heart',
      category: StickerCategory.sparkle,
      size: const Size(128, 128),
      paint: (c, s) => _glitterShape(c, s, _Shape.heart, const Color(0xFFFF8FB3)),
    ),
    StickerDef(
      id: 'glitter_circle',
      name: 'Glitter circle',
      category: StickerCategory.sparkle,
      size: const Size(120, 120),
      paint: (c, s) => _glitterShape(c, s, _Shape.circle, const Color(0xFFB8E8FF)),
    ),
    StickerDef(
      id: 'glitter_diamond',
      name: 'Glitter diamond',
      category: StickerCategory.sparkle,
      size: const Size(110, 130),
      paint: (c, s) => _glitterShape(c, s, _Shape.diamond, const Color(0xFFE4D4FF)),
    ),
    StickerDef(
      id: 'glitter_hex',
      name: 'Glitter hex',
      category: StickerCategory.sparkle,
      size: const Size(124, 124),
      paint: (c, s) => _glitterShape(c, s, _Shape.hex, const Color(0xFFC8F4D8)),
    ),
    StickerDef(
      id: 'glitter_triangle',
      name: 'Glitter triangle',
      category: StickerCategory.sparkle,
      size: const Size(124, 124),
      paint: (c, s) => _glitterShape(c, s, _Shape.triangle, const Color(0xFFFFE29A)),
    ),
    StickerDef(
      id: 'outline_star',
      name: 'Glue star',
      category: StickerCategory.sparkle,
      size: const Size(128, 128),
      paint: (c, s) => _glueOutline(c, s, _Shape.star, const Color(0xFFFF8FB3)),
    ),
    StickerDef(
      id: 'outline_heart',
      name: 'Glue heart',
      category: StickerCategory.sparkle,
      size: const Size(128, 128),
      paint: (c, s) => _glueOutline(c, s, _Shape.heart, const Color(0xFFB388EB)),
    ),
    StickerDef(
      id: 'outline_cloud',
      name: 'Glue cloud',
      category: StickerCategory.sparkle,
      size: const Size(140, 100),
      paint: (c, s) => _glueOutline(c, s, _Shape.cloud, const Color(0xFF7EC8E3)),
    ),
    StickerDef(
      id: 'plain_star',
      name: 'Star',
      category: StickerCategory.sparkle,
      size: const Size(120, 120),
      paint: (c, s) => _plainShape(c, s, _Shape.star, const Color(0xFFFFD36A)),
    ),
    StickerDef(
      id: 'plain_heart',
      name: 'Heart',
      category: StickerCategory.sparkle,
      size: const Size(120, 120),
      paint: (c, s) => _plainShape(c, s, _Shape.heart, const Color(0xFFFF7A9C)),
    ),
  ];
}

enum _Shape { star, heart, circle, diamond, hex, triangle, cloud }

Path _shapePath(_Shape shape, Size size) {
  final c = Offset(size.width / 2, size.height / 2);
  final r = min(size.width, size.height) * 0.38;
  switch (shape) {
    case _Shape.star:
      return starPath(c, r);
    case _Shape.heart:
      return heartPath(c, r * 1.15);
    case _Shape.circle:
      return Path()..addOval(Rect.fromCircle(center: c, radius: r));
    case _Shape.diamond:
      return diamondPath(c, r * 1.5, r * 2);
    case _Shape.hex:
      return _ngon(c, r, 6);
    case _Shape.triangle:
      return _ngon(c, r, 3, start: -pi / 2);
    case _Shape.cloud:
      return _cloud(c, size);
  }
}

Path _ngon(Offset c, double r, int n, {double start = 0}) {
  final path = Path();
  for (var i = 0; i < n; i++) {
    final a = start + i * 2 * pi / n;
    final p = Offset(c.dx + cos(a) * r, c.dy + sin(a) * r);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  return path;
}

Path _cloud(Offset c, Size size) {
  final path = Path();
  path.addOval(Rect.fromCircle(center: c + const Offset(-22, 6), radius: 22));
  path.addOval(Rect.fromCircle(center: c + const Offset(20, 8), radius: 20));
  path.addOval(Rect.fromCircle(center: c + const Offset(0, -8), radius: 24));
  path.addOval(Rect.fromCircle(center: c + const Offset(0, 12), radius: 18));
  return path;
}

void _scatterGlitter(Canvas canvas, Path path, int seed) {
  final bounds = path.getBounds();
  for (var i = 0; i < 38; i++) {
    final hx = hash01(seed, i);
    final hy = hash01(seed, i + 11);
    final p = Offset(
      bounds.left + hx * bounds.width,
      bounds.top + hy * bounds.height,
    );
    if (!path.contains(p)) continue;
    final size = 1.4 + hash01(seed, i + 23) * 2.4;
    final colors = [
      const Color(0xFFFFFFFF),
      const Color(0xFFFFF4C2),
      const Color(0xFFFFC6E0),
      const Color(0xFFC8F4E0),
    ];
    canvas.drawCircle(
      p,
      size,
      Paint()..color = colors[i % colors.length].withValues(alpha: 0.85),
    );
  }
}

void _glitterShape(Canvas canvas, Size size, _Shape shape, Color color) {
  final path = _shapePath(shape, size);
  canvas.drawPath(
    path.shift(const Offset(3, 4)),
    Paint()..color = const Color(0x33000000),
  );
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawPath(
    path,
    Paint()
      ..shader = linearShader(
        Offset(size.width * 0.2, size.height * 0.15),
        Offset(size.width * 0.8, size.height * 0.9),
        [
          const Color(0x88FFFFFF),
          color.withValues(alpha: 0.15),
          const Color(0x44FFFFFF),
        ],
      ),
  );
  _scatterGlitter(canvas, path, shape.index * 17 + color.toARGB32());
}

void _plainShape(Canvas canvas, Size size, _Shape shape, Color color) {
  final path = _shapePath(shape, size);
  canvas.drawPath(
    path.shift(const Offset(3, 4)),
    Paint()..color = const Color(0x33000000),
  );
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawPath(
    path,
    Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
}

void _glueOutline(Canvas canvas, Size size, _Shape shape, Color color) {
  final path = _shapePath(shape, size);
  final glue = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  canvas.drawPath(path, glue);
  canvas.drawPath(
    path,
    Paint()
      ..color = const Color(0xAAFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
  final metrics = path.computeMetrics();
  var i = 0;
  for (final m in metrics) {
    for (var d = 0.0; d < m.length; d += 8) {
      final t = m.getTangentForOffset(d);
      if (t == null) continue;
      final h = hash01(shape.index, i++);
      final p = t.position + Offset((h - 0.5) * 5, (hash01(i, 4) - 0.5) * 5);
      canvas.drawCircle(
        p,
        1.2 + h * 1.8,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFFFFFFF),
            color,
            0.25,
          )!.withValues(alpha: 0.9),
      );
    }
  }
}

List<StickerDef> _gems() {
  return [
    StickerDef(
      id: 'gem_pink',
      name: 'Pink gem',
      category: StickerCategory.gems,
      size: const Size(100, 120),
      paint: (c, s) => _gem(c, s, const Color(0xFFFF8FB3)),
    ),
    StickerDef(
      id: 'gem_mint',
      name: 'Mint gem',
      category: StickerCategory.gems,
      size: const Size(100, 120),
      paint: (c, s) => _gem(c, s, const Color(0xFF7ED9B8)),
    ),
    StickerDef(
      id: 'gem_lilac',
      name: 'Lilac gem',
      category: StickerCategory.gems,
      size: const Size(100, 120),
      paint: (c, s) => _gem(c, s, const Color(0xFFC9A0DC)),
    ),
    StickerDef(
      id: 'rhinestone',
      name: 'Rhinestone',
      category: StickerCategory.gems,
      size: const Size(96, 96),
      paint: _rhinestone,
    ),
  ];
}

void _gem(Canvas canvas, Size size, Color color) {
  final c = Offset(size.width / 2, size.height / 2);
  final top = Offset(c.dx, c.dy - 44);
  final bot = Offset(c.dx, c.dy + 46);
  final left = Offset(c.dx - 32, c.dy);
  final right = Offset(c.dx + 32, c.dy);
  final tl = Offset(c.dx - 16, c.dy - 18);
  final tr = Offset(c.dx + 16, c.dy - 18);
  final path = Path()
    ..moveTo(top.dx, top.dy)
    ..lineTo(tr.dx, tr.dy)
    ..lineTo(right.dx, right.dy)
    ..lineTo(bot.dx, bot.dy)
    ..lineTo(left.dx, left.dy)
    ..lineTo(tl.dx, tl.dy)
    ..close();
  canvas.drawPath(path.shift(const Offset(3, 4)), Paint()..color = const Color(0x33000000));
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawPath(
    Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(tl.dx, tl.dy)
      ..lineTo(c.dx, c.dy + 4)
      ..close(),
    Paint()..color = Color.lerp(color, Colors.white, 0.45)!,
  );
  canvas.drawPath(
    Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(c.dx, c.dy + 4)
      ..close(),
    Paint()..color = Color.lerp(color, Colors.white, 0.2)!,
  );
  canvas.drawPath(
    Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(bot.dx, bot.dy)
      ..lineTo(c.dx, c.dy + 4)
      ..close(),
    Paint()..color = Color.lerp(color, Colors.black, 0.18)!,
  );
  canvas.drawCircle(
    c + const Offset(-8, -16),
    4,
    Paint()..color = const Color(0xCCFFFFFF),
  );
}

void _rhinestone(Canvas canvas, Size size) {
  final c = Offset(size.width / 2, size.height / 2);
  canvas.drawCircle(c + const Offset(2, 3), 34, Paint()..color = const Color(0x33000000));
  canvas.drawCircle(
    c,
    32,
    Paint()
      ..shader = radialShader(c + const Offset(-8, -10), 36, [
        const Color(0xFFFFFFFF),
        const Color(0xFFE8F4FF),
        const Color(0xFFB8C4D8),
      ]),
  );
  canvas.drawCircle(c + const Offset(-10, -10), 7, Paint()..color = const Color(0xEEFFFFFF));
  for (var i = 0; i < 8; i++) {
    final a = i * pi / 4;
    canvas.drawCircle(
      c + Offset(cos(a) * 18, sin(a) * 18),
      2.2,
      Paint()..color = const Color(0xAAFFFFFF),
    );
  }
}

List<StickerDef> _notions() {
  return [
    StickerDef(
      id: 'button_pink',
      name: 'Pink button',
      category: StickerCategory.notions,
      size: const Size(96, 96),
      paint: (c, s) => _button(c, s, const Color(0xFFFFB0C8)),
    ),
    StickerDef(
      id: 'button_mint',
      name: 'Mint button',
      category: StickerCategory.notions,
      size: const Size(96, 96),
      paint: (c, s) => _button(c, s, const Color(0xFFA8E8C8)),
    ),
    StickerDef(
      id: 'sequin_gold',
      name: 'Gold sequin',
      category: StickerCategory.notions,
      size: const Size(84, 84),
      paint: (c, s) => _sequin(c, s, const Color(0xFFFFD36A)),
    ),
    StickerDef(
      id: 'sequin_silver',
      name: 'Silver sequin',
      category: StickerCategory.notions,
      size: const Size(84, 84),
      paint: (c, s) => _sequin(c, s, const Color(0xFFD8E0EC)),
    ),
    StickerDef(
      id: 'sticky_yellow',
      name: 'Yellow note',
      category: StickerCategory.notions,
      size: const Size(130, 130),
      paint: (c, s) => _sticky(c, s, const Color(0xFFFFF3A8)),
    ),
    StickerDef(
      id: 'sticky_pink',
      name: 'Pink note',
      category: StickerCategory.notions,
      size: const Size(130, 130),
      paint: (c, s) => _sticky(c, s, const Color(0xFFFFD0E0)),
    ),
    StickerDef(
      id: 'sticky_mint',
      name: 'Mint note',
      category: StickerCategory.notions,
      size: const Size(130, 130),
      paint: (c, s) => _sticky(c, s, const Color(0xFFC8F4DC)),
    ),
  ];
}

void _button(Canvas canvas, Size size, Color color) {
  final c = Offset(size.width / 2, size.height / 2);
  canvas.drawCircle(c + const Offset(2, 3), 34, Paint()..color = const Color(0x33000000));
  canvas.drawCircle(c, 33, Paint()..color = color);
  canvas.drawCircle(
    c,
    33,
    Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4,
  );
  const hole = 4.2;
  const d = 8.0;
  final holePaint = Paint()..color = const Color(0x66402030);
  canvas.drawCircle(c + const Offset(-d, -d), hole, holePaint);
  canvas.drawCircle(c + const Offset(d, -d), hole, holePaint);
  canvas.drawCircle(c + const Offset(-d, d), hole, holePaint);
  canvas.drawCircle(c + const Offset(d, d), hole, holePaint);
}

void _sequin(Canvas canvas, Size size, Color color) {
  final c = Offset(size.width / 2, size.height / 2);
  canvas.drawCircle(c + const Offset(1.5, 2), 26, Paint()..color = const Color(0x33000000));
  canvas.drawCircle(
    c,
    25,
    Paint()
      ..shader = linearShader(
        c + const Offset(-16, -16),
        c + const Offset(18, 18),
        [
          Color.lerp(color, Colors.white, 0.55)!,
          color,
          Color.lerp(color, Colors.black, 0.15)!,
        ],
      ),
  );
  canvas.drawCircle(c + const Offset(-8, -8), 6, Paint()..color = const Color(0xCCFFFFFF));
  canvas.drawCircle(c, 2.4, Paint()..color = const Color(0x66402030));
}

void _sticky(Canvas canvas, Size size, Color color) {
  final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
  final body = RRect.fromRectAndRadius(rect, const Radius.circular(6));
  canvas.drawRRect(body.shift(const Offset(3, 4)), Paint()..color = const Color(0x33000000));
  canvas.drawRRect(body, Paint()..color = color);
  final fold = Path()
    ..moveTo(rect.right - 22, rect.bottom)
    ..lineTo(rect.right, rect.bottom - 22)
    ..lineTo(rect.right, rect.bottom)
    ..close();
  canvas.drawPath(fold, Paint()..color = Color.lerp(color, Colors.black, 0.08)!);
  canvas.drawLine(
    Offset(rect.left + 12, rect.top + 18),
    Offset(rect.right - 12, rect.top + 18),
    Paint()
      ..color = const Color(0x33A07080)
      ..strokeWidth = 2,
  );
}

List<StickerDef> _faces() {
  return [
    StickerDef(
      id: 'smiley_plain',
      name: 'Smile',
      category: StickerCategory.faces,
      size: const Size(110, 110),
      paint: (c, s) => _smiley(c, s, glitter: false),
    ),
    StickerDef(
      id: 'smiley_glitter',
      name: 'Glitter smile',
      category: StickerCategory.faces,
      size: const Size(110, 110),
      paint: (c, s) => _smiley(c, s, glitter: true),
    ),
    StickerDef(
      id: 'heart_eyes',
      name: 'Heart eyes',
      category: StickerCategory.faces,
      size: const Size(110, 110),
      paint: _heartEyes,
    ),
  ];
}

void _smiley(Canvas canvas, Size size, {required bool glitter}) {
  final c = Offset(size.width / 2, size.height / 2);
  final face = Path()..addOval(Rect.fromCircle(center: c, radius: 42));
  canvas.drawPath(face.shift(const Offset(2, 3)), Paint()..color = const Color(0x33000000));
  canvas.drawPath(face, Paint()..color = const Color(0xFFFFE29A));
  if (glitter) {
    _scatterGlitter(canvas, face, 404);
  }
  canvas.drawCircle(c + const Offset(-14, -8), 5, Paint()..color = const Color(0xFF4A3038));
  canvas.drawCircle(c + const Offset(14, -8), 5, Paint()..color = const Color(0xFF4A3038));
  final smile = Path()
    ..moveTo(c.dx - 16, c.dy + 10)
    ..quadraticBezierTo(c.dx, c.dy + 24, c.dx + 16, c.dy + 10);
  canvas.drawPath(
    smile,
    Paint()
      ..color = const Color(0xFF4A3038)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round,
  );
}

void _heartEyes(Canvas canvas, Size size) {
  final c = Offset(size.width / 2, size.height / 2);
  canvas.drawCircle(c + const Offset(2, 3), 42, Paint()..color = const Color(0x33000000));
  canvas.drawCircle(c, 42, Paint()..color = const Color(0xFFFFE29A));
  canvas.drawPath(heartPath(c + const Offset(-15, -8), 10), Paint()..color = const Color(0xFFFF7A9C));
  canvas.drawPath(heartPath(c + const Offset(15, -8), 10), Paint()..color = const Color(0xFFFF7A9C));
  final smile = Path()
    ..moveTo(c.dx - 14, c.dy + 12)
    ..quadraticBezierTo(c.dx, c.dy + 22, c.dx + 14, c.dy + 12);
  canvas.drawPath(
    smile,
    Paint()
      ..color = const Color(0xFF4A3038)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round,
  );
}
