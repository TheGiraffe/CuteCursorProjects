import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_press/commands/command_stack.dart';
import 'package:petal_press/models/models.dart';

void main() {
  late Zine zine;
  late CommandStack stack;

  setUp(() {
    zine = Zine.create(title: 'undo me', pageCount: 3);
    stack = CommandStack();
  });

  test('stroke undo and redo', () {
    final pageId = zine.pages.first.id;
    final stroke = Stroke(
      id: 'ink1',
      points: const [StrokePoint(1, 1), StrokePoint(2, 4)],
      color: const Color(0xFF000000),
      thickness: 8,
      opacity: 1,
      sparkle: 0,
    );
    stack.execute(AddStrokeCommand(pageId, stroke), zine);
    expect(zine.pages.first.strokes, hasLength(1));
    stack.undo(zine);
    expect(zine.pages.first.strokes, isEmpty);
    stack.redo(zine);
    expect(zine.pages.first.strokes.single.id, 'ink1');
  });

  test('overlay and background undo', () {
    final pageId = zine.pages.first.id;
    final sticker = StickerInstance(
      id: 'st',
      catalogId: 'plain_heart',
      x: 40,
      y: 50,
      zIndex: 1,
    );
    stack.execute(AddOverlayCommand(pageId, sticker), zine);
    stack.execute(
      ChangeBackgroundCommand(
        pageId: pageId,
        before: zine.pages.first.background.copy(),
        after: PageBackground(pattern: BackgroundPattern.hearts),
      ),
      zine,
    );
    expect(zine.pages.first.overlays, hasLength(1));
    expect(zine.pages.first.background.pattern, BackgroundPattern.hearts);
    stack.undo(zine);
    expect(zine.pages.first.background.pattern, isNot(BackgroundPattern.hearts));
    stack.undo(zine);
    expect(zine.pages.first.overlays, isEmpty);
    expect(stack.canRedo, isTrue);
  });

  test('page add and delete undo', () {
    final extra = ZinePage.blank();
    stack.execute(AddPageCommand(extra, 1), zine);
    expect(zine.pages.length, 4);
    stack.execute(DeletePageCommand(extra, 1), zine);
    expect(zine.pages.length, 3);
    stack.undo(zine);
    expect(zine.pages.any((p) => p.id == extra.id), isTrue);
  });

  test('rename undo', () {
    stack.execute(RenameZineCommand(zine.title, 'new name'), zine);
    expect(zine.title, 'new name');
    stack.undo(zine);
    expect(zine.title, 'undo me');
  });
}
