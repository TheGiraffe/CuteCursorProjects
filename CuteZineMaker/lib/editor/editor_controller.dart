import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../commands/command_stack.dart';
import '../models/models.dart';
import '../persist/zine_store.dart';
import '../render/zine_painter.dart';

enum EditorTool { select, pen, sticker, text, background }

class EditorController extends ChangeNotifier {
  EditorController({
    required this.zine,
    required this.store,
  });

  Zine zine;
  final ZineStore store;
  final CommandStack stack = CommandStack();
  final PenSettings pen = PenSettings();

  int pageIndex = 0;
  EditorTool tool = EditorTool.pen;
  String? selectedId;
  String? pendingStickerId;
  Stroke? activeStroke;
  String? errorMessage;
  bool busy = false;
  bool dirty = false;

  _Grab? _grab;
  Timer? _saveTimer;

  ZinePage get page => zine.pages[pageIndex.clamp(0, zine.pages.length - 1)];

  OverlayItem? get selected =>
      selectedId == null ? null : page.overlayById(selectedId!);

  bool get canUndo => stack.canUndo;
  bool get canRedo => stack.canRedo;

  void _mark() {
    dirty = true;
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1200), () {
      unawaited(persist());
    });
  }

  void touch() => _mark();

  /// Pen settings are ephemeral UI state; refresh the chrome without a command.
  void refreshPen() => notifyListeners();

  void setTool(EditorTool next) {
    tool = next;
    if (next != EditorTool.select && next != EditorTool.sticker) {
      selectedId = null;
    }
    if (next != EditorTool.sticker) {
      pendingStickerId = null;
    }
    notifyListeners();
  }

  void setPage(int index) {
    pageIndex = index.clamp(0, zine.pages.length - 1);
    selectedId = null;
    notifyListeners();
  }

  void beginStroke(Offset pagePoint) {
    selectedId = null;
    activeStroke = Stroke(
      id: newId(),
      points: [StrokePoint(pagePoint.dx, pagePoint.dy)],
      color: pen.color,
      thickness: pen.thickness,
      opacity: pen.opacity,
      sparkle: pen.sparkle,
    );
    notifyListeners();
  }

  void appendStroke(Offset pagePoint) {
    final stroke = activeStroke;
    if (stroke == null) return;
    final last = stroke.points.last;
    if ((pagePoint - last.offset).distance < 1.2) return;
    stroke.points.add(StrokePoint(pagePoint.dx, pagePoint.dy));
    notifyListeners();
  }

  void endStroke() {
    final stroke = activeStroke;
    activeStroke = null;
    if (stroke == null || stroke.points.isEmpty) {
      notifyListeners();
      return;
    }
    stack.execute(AddStrokeCommand(page.id, stroke), zine);
    _mark();
  }

  void pickSticker(String catalogId) {
    pendingStickerId = catalogId;
    tool = EditorTool.sticker;
    notifyListeners();
  }

  void stampSticker(Offset pagePoint) {
    final catalogId = pendingStickerId;
    if (catalogId == null) return;
    final sticker = StickerInstance(
      id: newId(),
      catalogId: catalogId,
      x: pagePoint.dx,
      y: pagePoint.dy,
      zIndex: page.nextZIndex(),
    );
    stack.execute(AddOverlayCommand(page.id, sticker), zine);
    selectedId = sticker.id;
    _mark();
  }

  void addText(Offset pagePoint, {String text = 'hello'}) {
    final box = TextBoxItem(
      id: newId(),
      text: text,
      x: pagePoint.dx,
      y: pagePoint.dy,
      zIndex: page.nextZIndex(),
    );
    stack.execute(AddOverlayCommand(page.id, box), zine);
    selectedId = box.id;
    tool = EditorTool.select;
    _mark();
  }

  void tapSelect(Offset pagePoint) {
    final hit = ZinePainter.hitTestOverlay(page, pagePoint);
    selectedId = hit?.id;
    notifyListeners();
  }

  void beginGrab(Offset pagePoint) {
    final item = selected ?? ZinePainter.hitTestOverlay(page, pagePoint);
    if (item == null) {
      selectedId = null;
      _grab = null;
      notifyListeners();
      return;
    }
    selectedId = item.id;
    _grab = _Grab(
      itemId: item.id,
      startX: item.x,
      startY: item.y,
      startScale: item.scale,
      startRotation: item.rotation,
      grabPoint: pagePoint,
    );
    notifyListeners();
  }

  void updateGrab(Offset pagePoint, {double scale = 1, double rotation = 0}) {
    final grab = _grab;
    final item = selected;
    if (grab == null || item == null || item.id != grab.itemId) return;
    item.x = grab.startX + (pagePoint.dx - grab.grabPoint.dx);
    item.y = grab.startY + (pagePoint.dy - grab.grabPoint.dy);
    item.scale = (grab.startScale * scale).clamp(0.25, 6.0);
    item.rotation = grab.startRotation + rotation;
    notifyListeners();
  }

  void endGrab() {
    final grab = _grab;
    final item = selected;
    _grab = null;
    if (grab == null || item == null) return;
    if (item.x == grab.startX &&
        item.y == grab.startY &&
        item.scale == grab.startScale &&
        item.rotation == grab.startRotation) {
      return;
    }
    stack.execute(
      TransformOverlayCommand(
        pageId: page.id,
        itemId: item.id,
        beforeX: grab.startX,
        beforeY: grab.startY,
        beforeScale: grab.startScale,
        beforeRotation: grab.startRotation,
        afterX: item.x,
        afterY: item.y,
        afterScale: item.scale,
        afterRotation: item.rotation,
      ),
      zine,
    );
    _mark();
  }

  void updateSelectedText({String? text, Color? color, double? fontSize}) {
    final item = selected;
    if (item is! TextBoxItem) return;
    final before = item.copy();
    if (text != null) item.text = text;
    if (color != null) item.color = color;
    if (fontSize != null) item.fontSize = fontSize;
    stack.execute(
      UpdateTextCommand(
        pageId: page.id,
        itemId: item.id,
        beforeText: before.text,
        beforeColor: colorToArgb(before.color),
        beforeSize: before.fontSize,
        afterText: item.text,
        afterColor: colorToArgb(item.color),
        afterSize: item.fontSize,
      ),
      zine,
    );
    _mark();
  }

  void deleteSelected() {
    final item = selected;
    if (item == null) return;
    stack.execute(RemoveOverlayCommand(page.id, item.copy()), zine);
    selectedId = null;
    _mark();
  }

  void bringForward() {
    final item = selected;
    if (item == null) return;
    final after = page.nextZIndex();
    stack.execute(
      ReorderOverlayCommand(
        pageId: page.id,
        itemId: item.id,
        beforeZ: item.zIndex,
        afterZ: after,
      ),
      zine,
    );
    _mark();
  }

  void sendBack() {
    final item = selected;
    if (item == null) return;
    var minZ = item.zIndex;
    for (final o in page.overlays) {
      if (o.zIndex < minZ) minZ = o.zIndex;
    }
    stack.execute(
      ReorderOverlayCommand(
        pageId: page.id,
        itemId: item.id,
        beforeZ: item.zIndex,
        afterZ: minZ - 1,
      ),
      zine,
    );
    _mark();
  }

  void changeBackground(PageBackground next) {
    stack.execute(
      ChangeBackgroundCommand(
        pageId: page.id,
        before: page.background.copy(),
        after: next.copy(),
      ),
      zine,
    );
    _mark();
  }

  void addPage() {
    final blank = ZinePage.blank();
    stack.execute(AddPageCommand(blank, pageIndex + 1), zine);
    pageIndex = pageIndex + 1;
    selectedId = null;
    _mark();
  }

  void deletePage() {
    if (zine.pages.length <= 1) return;
    final doomed = page.copy();
    final index = pageIndex;
    stack.execute(DeletePageCommand(doomed, index), zine);
    pageIndex = index.clamp(0, zine.pages.length - 1);
    selectedId = null;
    _mark();
  }

  void reorderPages(int from, int to) {
    if (from == to) return;
    stack.execute(ReorderPagesCommand(from, to), zine);
    pageIndex = to;
    _mark();
  }

  void rename(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed == zine.title) return;
    stack.execute(RenameZineCommand(zine.title, trimmed), zine);
    _mark();
  }

  void undo() {
    stack.undo(zine);
    pageIndex = pageIndex.clamp(0, zine.pages.length - 1);
    selectedId = null;
    _mark();
  }

  void redo() {
    stack.redo(zine);
    pageIndex = pageIndex.clamp(0, zine.pages.length - 1);
    selectedId = null;
    _mark();
  }

  Future<void> persist() async {
    try {
      Uint8List? thumb;
      try {
        thumb = await rasterizePagePng(zine.pages.first, scale: 0.22);
      } catch (_) {
        thumb = null;
      }
      await store.save(zine, thumbnail: thumb);
      dirty = false;
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Could not save this zine.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

class _Grab {
  _Grab({
    required this.itemId,
    required this.startX,
    required this.startY,
    required this.startScale,
    required this.startRotation,
    required this.grabPoint,
  });

  final String itemId;
  final double startX, startY, startScale, startRotation;
  final Offset grabPoint;
}
