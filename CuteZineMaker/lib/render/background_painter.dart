import 'dart:math';

import 'package:flutter/material.dart';

import '../models/models.dart';
import 'draw_helpers.dart';

void paintPageBackground(Canvas canvas, Size size, PageBackground bg) {
  canvas.drawRect(Offset.zero & size, Paint()..color = bg.color);
  final accent = bg.patternColor ?? _autoAccent(bg.color);
  switch (bg.pattern) {
    case BackgroundPattern.solid:
      break;
    case BackgroundPattern.hearts:
      _hearts(canvas, size, accent);
    case BackgroundPattern.palaka:
      _palaka(canvas, size, bg.color, accent);
    case BackgroundPattern.waves:
      _waves(canvas, size, accent);
    case BackgroundPattern.dots:
      _dots(canvas, size, accent);
    case BackgroundPattern.stars:
      _stars(canvas, size, accent);
    case BackgroundPattern.gingham:
      _gingham(canvas, size, bg.color, accent);
  }
}

Color _autoAccent(Color base) {
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withSaturation(min(1, hsl.saturation + 0.25))
      .withLightness((hsl.lightness * 0.72).clamp(0.25, 0.72))
      .toColor()
      .withValues(alpha: 0.45);
}

void _hearts(Canvas canvas, Size size, Color color) {
  const step = 54.0;
  final paint = Paint()..color = color.withValues(alpha: 0.38);
  for (var y = 16.0, row = 0; y < size.height + step; y += step, row++) {
    for (var x = row.isEven ? 16.0 : 43.0; x < size.width + step; x += step) {
      canvas.drawPath(heartPath(Offset(x, y), 11), paint);
    }
  }
}

/// Hawaiian palaka: overlapping pastel plaid bands.
void _palaka(Canvas canvas, Size size, Color base, Color accent) {
  const cell = 40.0;
  final light = Color.lerp(base, const Color(0xFFFFFFFF), 0.45)!
      .withValues(alpha: 0.55);
  final dark = Color.lerp(accent, base, 0.25)!.withValues(alpha: 0.38);
  final cross = Color.lerp(accent, const Color(0xFF4A6A88), 0.15)!
      .withValues(alpha: 0.28);
  final vPaint = Paint()..color = light;
  final hPaint = Paint()..color = dark;
  final xPaint = Paint()..color = cross;
  for (var x = 0.0; x < size.width; x += cell) {
    canvas.drawRect(Rect.fromLTWH(x + cell * 0.28, 0, cell * 0.22, size.height), vPaint);
    canvas.drawRect(Rect.fromLTWH(x + cell * 0.62, 0, cell * 0.08, size.height), vPaint);
  }
  for (var y = 0.0; y < size.height; y += cell) {
    canvas.drawRect(Rect.fromLTWH(0, y + cell * 0.28, size.width, cell * 0.22), hPaint);
    canvas.drawRect(Rect.fromLTWH(0, y + cell * 0.62, size.width, cell * 0.08), hPaint);
  }
  for (var x = 0.0; x < size.width; x += cell) {
    for (var y = 0.0; y < size.height; y += cell) {
      canvas.drawRect(
        Rect.fromLTWH(x + cell * 0.28, y + cell * 0.28, cell * 0.22, cell * 0.22),
        xPaint,
      );
    }
  }
}

void _waves(Canvas canvas, Size size, Color color) {
  final paint = Paint()
    ..color = color.withValues(alpha: 0.42)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.2
    ..strokeCap = StrokeCap.round;
  const row = 28.0;
  for (var y = 18.0, i = 0; y < size.height; y += row, i++) {
    final path = Path();
    path.moveTo(-10, y);
    for (var x = 0.0; x <= size.width + 20; x += 18) {
      final amp = 7.0 + (i % 3) * 1.4;
      path.quadraticBezierTo(x + 9, y + ((x ~/ 18).isEven ? -amp : amp), x + 18, y);
    }
    canvas.drawPath(path, paint);
  }
}

void _dots(Canvas canvas, Size size, Color color) {
  final paint = Paint()..color = color.withValues(alpha: 0.4);
  const step = 28.0;
  for (var y = 14.0, row = 0; y < size.height; y += step, row++) {
    for (var x = row.isEven ? 14.0 : 28.0; x < size.width; x += step) {
      canvas.drawCircle(Offset(x, y), 3.4, paint);
    }
  }
}

void _stars(Canvas canvas, Size size, Color color) {
  final paint = Paint()..color = color.withValues(alpha: 0.4);
  const step = 52.0;
  for (var y = 20.0, row = 0; y < size.height; y += step, row++) {
    for (var x = row.isEven ? 20.0 : 46.0; x < size.width; x += step) {
      canvas.drawPath(starPath(Offset(x, y), 8.5), paint);
    }
  }
}

void _gingham(Canvas canvas, Size size, Color base, Color accent) {
  const cell = 28.0;
  final a = Color.lerp(base, accent, 0.45)!.withValues(alpha: 0.28);
  final b = Color.lerp(base, accent, 0.7)!.withValues(alpha: 0.18);
  final paintA = Paint()..color = a;
  final paintB = Paint()..color = b;
  for (var x = 0.0, col = 0; x < size.width; x += cell, col++) {
    if (col.isEven) {
      canvas.drawRect(Rect.fromLTWH(x, 0, cell, size.height), paintA);
    }
  }
  for (var y = 0.0, row = 0; y < size.height; y += cell, row++) {
    if (row.isEven) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, cell), paintB);
    }
  }
}
