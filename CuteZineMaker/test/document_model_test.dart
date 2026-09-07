import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_press/models/models.dart';

void main() {
  test('page size is 1/8 of US Letter', () {
    expect(ZinePageSize.widthInches, 2.75);
    expect(ZinePageSize.heightInches, 4.25);
    expect(ZinePageSize.dpi, 300);
    expect(ZinePageSize.logicalWidth, 825);
    expect(ZinePageSize.logicalHeight, 1275);
    expect(8.5 / 2, ZinePageSize.heightInches); // 4.25
    expect(11 / 4, ZinePageSize.widthInches); // 2.75
    expect(ZinePageSize.defaultPageCount, 8);
  });

  test('new zine starts with eight blank pages', () {
    final zine = Zine.create(title: 'pocket pal');
    expect(zine.title, 'pocket pal');
    expect(zine.pages.length, 8);
    expect(zine.pages.every((p) => p.strokes.isEmpty), isTrue);
    expect(zine.pages.every((p) => p.overlays.isEmpty), isTrue);
  });

  test('document JSON round-trips strokes, stickers, and text', () {
    final zine = Zine.create(title: 'scrap', pageCount: 2);
    zine.pages[0].strokes.add(
      Stroke(
        id: 's1',
        points: const [StrokePoint(10, 20), StrokePoint(30, 40)],
        color: const Color(0xFFE88AA8),
        thickness: 12,
        opacity: 0.8,
        sparkle: 0.6,
      ),
    );
    zine.pages[0].overlays.add(
      StickerInstance(
        id: 'st1',
        catalogId: 'glitter_star',
        x: 200,
        y: 300,
        scale: 1.2,
        rotation: 0.3,
        zIndex: 1,
      ),
    );
    zine.pages[0].overlays.add(
      TextBoxItem(
        id: 't1',
        text: 'hello',
        x: 100,
        y: 140,
        zIndex: 2,
        color: const Color(0xFF5A3E4A),
        fontSize: 28,
      ),
    );
    zine.pages[0].background = PageBackground(
      color: const Color(0xFFFFF0F4),
      pattern: BackgroundPattern.palaka,
    );

    final copy = Zine.fromJson(zine.toJson());
    expect(copy.title, 'scrap');
    expect(copy.pages.length, 2);
    expect(copy.pages[0].strokes.single.points.length, 2);
    expect(copy.pages[0].strokes.single.sparkle, 0.6);
    expect(copy.pages[0].overlays.length, 2);
    expect((copy.pages[0].overlays[0] as StickerInstance).catalogId, 'glitter_star');
    expect((copy.pages[0].overlays[1] as TextBoxItem).text, 'hello');
    expect(copy.pages[0].background.pattern, BackgroundPattern.palaka);
    expect(copy.toJson()['pageWidthInches'], 2.75);
    expect(copy.toJson()['pageHeightInches'], 4.25);
  });

  test('custom page counts are allowed', () {
    expect(Zine.create(pageCount: 4).pages.length, 4);
    expect(Zine.create(pageCount: 16).pages.length, 16);
    expect(Zine.create(pageCount: 0).pages.length, 1);
  });
}
