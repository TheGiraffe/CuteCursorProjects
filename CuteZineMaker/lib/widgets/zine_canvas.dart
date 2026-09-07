import 'package:flutter/material.dart';

import '../editor/editor_controller.dart';
import '../models/models.dart';
import '../render/zine_painter.dart';
import '../theme.dart';

class ZineCanvas extends StatefulWidget {
  const ZineCanvas({super.key, required this.controller});

  final EditorController controller;

  @override
  State<ZineCanvas> createState() => _ZineCanvasState();
}

class _ZineCanvasState extends State<ZineCanvas> {
  double _scaleAccum = 1;
  double _rotAccum = 0;

  EditorController get c => widget.controller;

  Offset _toPage(Offset local, Size size) {
    return Offset(
      local.dx / size.width * ZinePageSize.logicalWidth,
      local.dy / size.height * ZinePageSize.logicalHeight,
    );
  }

  void _onPointerDown(Offset page) {
    switch (c.tool) {
      case EditorTool.pen:
        c.beginStroke(page);
      case EditorTool.sticker:
        c.stampSticker(page);
      case EditorTool.text:
        c.addText(page);
      case EditorTool.select:
      case EditorTool.background:
        c.beginGrab(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;
            var w = maxW;
            var h = w / ZinePageSize.aspectRatio;
            if (h > maxH) {
              h = maxH;
              w = h * ZinePageSize.aspectRatio;
            }
            return Center(
              child: Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: PetalColors.lavender.withValues(alpha: 0.28),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                    const BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(2, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Listener(
                    onPointerDown: (e) {
                      if (c.tool == EditorTool.pen) {
                        _onPointerDown(_toPage(e.localPosition, Size(w, h)));
                      }
                    },
                    onPointerMove: (e) {
                      if (c.tool == EditorTool.pen) {
                        c.appendStroke(_toPage(e.localPosition, Size(w, h)));
                      }
                    },
                    onPointerUp: (_) {
                      if (c.tool == EditorTool.pen) c.endStroke();
                    },
                    onPointerCancel: (_) {
                      if (c.tool == EditorTool.pen) c.endStroke();
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: c.tool == EditorTool.pen
                          ? null
                          : (d) => _onPointerDown(_toPage(d.localPosition, Size(w, h))),
                      onScaleStart: c.tool == EditorTool.pen
                          ? null
                          : (d) {
                              _scaleAccum = 1;
                              _rotAccum = 0;
                              if (c.tool == EditorTool.select ||
                                  c.tool == EditorTool.background) {
                                c.beginGrab(_toPage(d.localFocalPoint, Size(w, h)));
                              }
                            },
                      onScaleUpdate: c.tool == EditorTool.pen
                          ? null
                          : (d) {
                              if (c.tool != EditorTool.select &&
                                  c.tool != EditorTool.background) {
                                return;
                              }
                              final pagePt = _toPage(d.localFocalPoint, Size(w, h));
                              _scaleAccum = d.scale;
                              _rotAccum = d.rotation;
                              c.updateGrab(
                                pagePt,
                                scale: _scaleAccum,
                                rotation: _rotAccum,
                              );
                            },
                      onScaleEnd: c.tool == EditorTool.pen
                          ? null
                          : (_) => c.endGrab(),
                      onDoubleTap: () async {
                        final item = c.selected;
                        if (item is TextBoxItem && context.mounted) {
                          // Editing happens via the inspector on the editor screen.
                        }
                      },
                      child: CustomPaint(
                        painter: ZinePainter(
                          page: c.page,
                          activeStroke: c.activeStroke,
                          selectedId: c.selectedId,
                        ),
                        size: Size(w, h),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
