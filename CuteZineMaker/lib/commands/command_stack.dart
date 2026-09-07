import '../models/models.dart';

/// Undo/redo command. Mutates [Zine] in place.
abstract class EditorCommand {
  void redo(Zine zine);
  void undo(Zine zine);
}

class CommandStack {
  final List<EditorCommand> _undo = [];
  final List<EditorCommand> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get undoCount => _undo.length;
  int get redoCount => _redo.length;

  void execute(EditorCommand command, Zine zine) {
    command.redo(zine);
    _undo.add(command);
    _redo.clear();
    zine.updatedAt = DateTime.now();
  }

  void undo(Zine zine) {
    if (_undo.isEmpty) return;
    final command = _undo.removeLast();
    command.undo(zine);
    _redo.add(command);
    zine.updatedAt = DateTime.now();
  }

  void redo(Zine zine) {
    if (_redo.isEmpty) return;
    final command = _redo.removeLast();
    command.redo(zine);
    _undo.add(command);
    zine.updatedAt = DateTime.now();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}

ZinePage _page(Zine zine, String pageId) => zine.pageById(pageId);

class AddStrokeCommand implements EditorCommand {
  AddStrokeCommand(this.pageId, this.stroke);

  final String pageId;
  final Stroke stroke;

  @override
  void redo(Zine zine) => _page(zine, pageId).strokes.add(stroke);

  @override
  void undo(Zine zine) =>
      _page(zine, pageId).strokes.removeWhere((s) => s.id == stroke.id);
}

class AddOverlayCommand implements EditorCommand {
  AddOverlayCommand(this.pageId, this.item);

  final String pageId;
  final OverlayItem item;

  @override
  void redo(Zine zine) => _page(zine, pageId).overlays.add(item);

  @override
  void undo(Zine zine) =>
      _page(zine, pageId).overlays.removeWhere((o) => o.id == item.id);
}

class RemoveOverlayCommand implements EditorCommand {
  RemoveOverlayCommand(this.pageId, this.item);

  final String pageId;
  final OverlayItem item;

  @override
  void redo(Zine zine) =>
      _page(zine, pageId).overlays.removeWhere((o) => o.id == item.id);

  @override
  void undo(Zine zine) => _page(zine, pageId).overlays.add(item.copy());
}

class TransformOverlayCommand implements EditorCommand {
  TransformOverlayCommand({
    required this.pageId,
    required this.itemId,
    required this.beforeX,
    required this.beforeY,
    required this.beforeScale,
    required this.beforeRotation,
    required this.afterX,
    required this.afterY,
    required this.afterScale,
    required this.afterRotation,
  });

  final String pageId;
  final String itemId;
  final double beforeX, beforeY, beforeScale, beforeRotation;
  final double afterX, afterY, afterScale, afterRotation;

  @override
  void redo(Zine zine) => _apply(
        zine,
        afterX,
        afterY,
        afterScale,
        afterRotation,
      );

  @override
  void undo(Zine zine) => _apply(
        zine,
        beforeX,
        beforeY,
        beforeScale,
        beforeRotation,
      );

  void _apply(Zine zine, double x, double y, double scale, double rotation) {
    final item = _page(zine, pageId).overlayById(itemId);
    if (item == null) return;
    item.x = x;
    item.y = y;
    item.scale = scale;
    item.rotation = rotation;
  }
}

class UpdateTextCommand implements EditorCommand {
  UpdateTextCommand({
    required this.pageId,
    required this.itemId,
    required this.beforeText,
    required this.beforeColor,
    required this.beforeSize,
    required this.afterText,
    required this.afterColor,
    required this.afterSize,
  });

  final String pageId;
  final String itemId;
  final String beforeText;
  final int beforeColor;
  final double beforeSize;
  final String afterText;
  final int afterColor;
  final double afterSize;

  @override
  void redo(Zine zine) => _apply(zine, afterText, afterColor, afterSize);

  @override
  void undo(Zine zine) => _apply(zine, beforeText, beforeColor, beforeSize);

  void _apply(Zine zine, String text, int color, double size) {
    final item = _page(zine, pageId).overlayById(itemId);
    if (item is! TextBoxItem) return;
    item.text = text;
    item.color = colorFromArgb(color);
    item.fontSize = size;
  }
}

class ChangeBackgroundCommand implements EditorCommand {
  ChangeBackgroundCommand({
    required this.pageId,
    required this.before,
    required this.after,
  });

  final String pageId;
  final PageBackground before;
  final PageBackground after;

  @override
  void redo(Zine zine) => _page(zine, pageId).background = after.copy();

  @override
  void undo(Zine zine) => _page(zine, pageId).background = before.copy();
}

class ReorderOverlayCommand implements EditorCommand {
  ReorderOverlayCommand({
    required this.pageId,
    required this.itemId,
    required this.beforeZ,
    required this.afterZ,
  });

  final String pageId;
  final String itemId;
  final int beforeZ;
  final int afterZ;

  @override
  void redo(Zine zine) {
    final item = _page(zine, pageId).overlayById(itemId);
    if (item != null) item.zIndex = afterZ;
  }

  @override
  void undo(Zine zine) {
    final item = _page(zine, pageId).overlayById(itemId);
    if (item != null) item.zIndex = beforeZ;
  }
}

class AddPageCommand implements EditorCommand {
  AddPageCommand(this.page, this.index);

  final ZinePage page;
  final int index;

  @override
  void redo(Zine zine) {
    final i = index.clamp(0, zine.pages.length);
    zine.pages.insert(i, page);
  }

  @override
  void undo(Zine zine) => zine.pages.removeWhere((p) => p.id == page.id);
}

class DeletePageCommand implements EditorCommand {
  DeletePageCommand(this.page, this.index);

  final ZinePage page;
  final int index;

  @override
  void redo(Zine zine) {
    if (zine.pages.length <= 1) return;
    zine.pages.removeWhere((p) => p.id == page.id);
  }

  @override
  void undo(Zine zine) {
    final i = index.clamp(0, zine.pages.length);
    if (zine.pages.any((p) => p.id == page.id)) return;
    zine.pages.insert(i, page.copy());
  }
}

class ReorderPagesCommand implements EditorCommand {
  ReorderPagesCommand(this.from, this.to);

  final int from;
  final int to;

  @override
  void redo(Zine zine) => _move(zine, from, to);

  @override
  void undo(Zine zine) => _move(zine, to, from);

  void _move(Zine zine, int a, int b) {
    if (a < 0 || b < 0 || a >= zine.pages.length || b >= zine.pages.length) {
      return;
    }
    final page = zine.pages.removeAt(a);
    zine.pages.insert(b, page);
  }
}

class RenameZineCommand implements EditorCommand {
  RenameZineCommand(this.before, this.after);

  final String before;
  final String after;

  @override
  void redo(Zine zine) => zine.title = after;

  @override
  void undo(Zine zine) => zine.title = before;
}
