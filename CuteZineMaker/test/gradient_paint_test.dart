import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:petal_press/render/draw_helpers.dart';
import 'package:petal_press/render/sticker_catalog.dart';

void main() {
  test('ui gradients accept 1, 2, or 3 colors without throwing', () {
    expect(
      () => linearShader(Offset.zero, const Offset(10, 10), const [Color(0xFFFF0000)]),
      returnsNormally,
    );
    expect(
      () => linearShader(Offset.zero, const Offset(10, 10), const [
        Color(0xFFFF0000),
        Color(0xFF00FF00),
      ]),
      returnsNormally,
    );
    expect(
      () => linearShader(Offset.zero, const Offset(10, 10), const [
        Color(0x88FFFFFF),
        Color(0x22FF88AA),
        Color(0x44FFFFFF),
      ]),
      returnsNormally,
    );
    expect(
      () => radialShader(Offset.zero, 12, const [
        Color(0xFFFFFFFF),
        Color(0xFFE8F4FF),
        Color(0xFFB8C4D8),
      ]),
      returnsNormally,
    );
  });

  test('glitter, gem, and sequin stickers paint without crashing', () {
    const ids = [
      'glitter_star',
      'glitter_heart',
      'glitter_circle',
      'glitter_diamond',
      'glitter_hex',
      'glitter_triangle',
      'rhinestone',
      'sequin_gold',
      'sequin_silver',
    ];
    for (final id in ids) {
      final def = StickerCatalog.byId(id);
      expect(def, isNotNull, reason: id);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => def!.paint(canvas, def.size), returnsNormally, reason: id);
      recorder.endRecording().dispose();
    }
  });
}
