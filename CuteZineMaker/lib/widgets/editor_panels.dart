import 'package:flutter/material.dart';

import '../editor/editor_controller.dart';
import '../models/models.dart';
import '../render/sticker_catalog.dart';
import '../render/zine_painter.dart';
import '../theme.dart';
import 'cute_chrome.dart';

List<Widget> buildToolButtons(EditorController controller, {double size = 46}) {
  const tools = <(EditorTool, IconData, String)>[
    (EditorTool.select, Icons.pan_tool_alt_rounded, 'Select'),
    (EditorTool.pen, Icons.edit_rounded, 'Pen'),
    (EditorTool.sticker, Icons.auto_awesome_rounded, 'Stickers'),
    (EditorTool.text, Icons.title_rounded, 'Text'),
    (EditorTool.background, Icons.wallpaper_rounded, 'Background'),
  ];
  return [
    for (var i = 0; i < tools.length; i++)
      CuteIconButton(
        icon: tools[i].$2,
        tooltip: tools[i].$3,
        selected: controller.tool == tools[i].$1,
        accent: PetalColors.accentAt(i),
        size: size,
        onTap: () => controller.setTool(tools[i].$1),
      ),
  ];
}

class ToolRail extends StatelessWidget {
  const ToolRail({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return PaperPanel(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: buildToolButtons(controller),
          ),
        );
      },
    );
  }
}

class SideToolMenu extends StatelessWidget {
  const SideToolMenu({
    super.key,
    required this.controller,
    required this.expanded,
    required this.onToggle,
    required this.options,
  });

  final EditorController controller;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget options;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: expanded ? 320 : 72,
          child: PaperPanel(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CuteIconButton(
                    icon: expanded
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    tooltip: expanded ? 'Collapse tools' : 'Expand tools',
                    accent: PetalColors.lavender,
                    size: 40,
                    onTap: onToggle,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  for (final button in buildToolButtons(controller, size: 44))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: button,
                    ),
                ],
                if (expanded) ...[
                  const SizedBox(height: 4),
                  Expanded(child: SingleChildScrollView(child: options)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget editorToolOptions(EditorController controller) {
  if (controller.selectedId != null) {
    return OverlayInspector(controller: controller);
  }
  switch (controller.tool) {
    case EditorTool.pen:
      return PenControls(controller: controller);
    case EditorTool.sticker:
      return StickerDrawer(controller: controller);
    case EditorTool.background:
      return BackgroundControls(controller: controller);
    case EditorTool.text:
      return const PaperPanel(
        child: Text(
          'Tap the page to drop a text box, then edit it from the inspector.',
          style: TextStyle(color: PetalColors.muted),
        ),
      );
    case EditorTool.select:
      return const PaperPanel(
        child: Text(
          'Tap a sticker or text to move, pinch to scale, or use the sliders.',
          style: TextStyle(color: PetalColors.muted),
        ),
      );
  }
}

class PenControls extends StatelessWidget {
  const PenControls({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final pen = controller.pen;
    return PaperPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in PetalPalette.pens)
                ColorChip(
                  color: color,
                  selected: colorToArgb(pen.color) == colorToArgb(color),
                  onTap: () {
                    pen.color = color;
                    controller.refreshPen();
                  },
                ),
              GestureDetector(
                onTap: () => showCuteColorPicker(
                  context: context,
                  color: pen.color,
                  onPicked: (c) {
                    pen.color = c;
                    controller.refreshPen();
                  },
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Colors.red,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Colors.purple,
                        Colors.red,
                      ],
                    ),
                    border: Border.all(color: PetalColors.ink, width: 2),
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          _labeledSlider(
            'Thickness',
            (pen.thickness - 3) / 45,
            (v) {
              pen.thickness = 3 + v * 45;
              controller.refreshPen();
            },
          ),
          _labeledSlider(
            'Opacity',
            pen.opacity,
            (v) {
              pen.opacity = v.clamp(0.15, 1);
              controller.refreshPen();
            },
          ),
          Row(
            children: [
              Expanded(
                child: _labeledSlider(
                  'Sparkle',
                  pen.sparkle,
                  (v) {
                    pen.sparkle = v;
                    controller.refreshPen();
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Glitter'),
                selected: pen.sparkle > 0.15,
                selectedColor: PetalColors.lemon,
                onSelected: (on) {
                  pen.sparkle = on ? 0.85 : 0;
                  controller.refreshPen();
                },
                avatar: const Icon(Icons.auto_awesome, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _labeledSlider(String label, double value, ValueChanged<double> onChanged) {
  return Row(
    children: [
      SizedBox(
        width: 78,
        child: Text(label, style: const TextStyle(fontSize: 13, color: PetalColors.muted)),
      ),
      Expanded(
        child: Slider(
          value: value.clamp(0, 1),
          onChanged: onChanged,
          activeColor: PetalColors.sky,
        ),
      ),
    ],
  );
}

class BackgroundControls extends StatelessWidget {
  const BackgroundControls({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final bg = controller.page.background;
    return PaperPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Page paper', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in PetalPalette.papers)
                ColorChip(
                  color: color,
                  selected: colorToArgb(bg.color) == colorToArgb(color),
                  onTap: () => controller.changeBackground(
                    PageBackground(color: color, pattern: bg.pattern, patternColor: bg.patternColor),
                  ),
                ),
              GestureDetector(
                onTap: () => showCuteColorPicker(
                  context: context,
                  color: bg.color,
                  onPicked: (c) => controller.changeBackground(
                    PageBackground(color: c, pattern: bg.pattern, patternColor: bg.patternColor),
                  ),
                ),
                child: const Icon(Icons.colorize_rounded, color: PetalColors.lavender),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final pattern in BackgroundPattern.values)
                ChoiceChip(
                  label: Text(_patternName(pattern)),
                  selected: bg.pattern == pattern,
                  selectedColor: PetalColors.mint,
                  onSelected: (_) => controller.changeBackground(
                    PageBackground(color: bg.color, pattern: pattern, patternColor: bg.patternColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _patternName(BackgroundPattern p) => switch (p) {
        BackgroundPattern.solid => 'Solid',
        BackgroundPattern.hearts => 'Hearts',
        BackgroundPattern.palaka => 'Palaka',
        BackgroundPattern.waves => 'Waves',
        BackgroundPattern.dots => 'Dots',
        BackgroundPattern.stars => 'Stars',
        BackgroundPattern.gingham => 'Gingham',
      };
}

class StickerDrawer extends StatelessWidget {
  const StickerDrawer({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: StickerCategory.values.length,
      child: PaperPanel(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Sticker tin — tap a stamp, then tap the page',
                style: TextStyle(fontSize: 13, color: PetalColors.muted),
              ),
            ),
            TabBar(
              isScrollable: true,
              labelColor: PetalColors.ink,
              indicatorColor: PetalColors.sky,
              tabs: [
                for (final cat in StickerCategory.values)
                  Tab(text: _catName(cat), height: 32),
              ],
            ),
            SizedBox(
              height: 148,
              child: TabBarView(
                children: [
                  for (final cat in StickerCategory.values)
                    GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: StickerCatalog.inCategory(cat).length,
                      itemBuilder: (context, i) {
                        final def = StickerCatalog.inCategory(cat)[i];
                        final selected = controller.pendingStickerId == def.id;
                        return GestureDetector(
                          onTap: () => controller.pickSticker(def.id),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: selected ? PetalColors.lemon : PetalColors.cream,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? PetalColors.sky : const Color(0x334A3A52),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: CustomPaint(
                              painter: _StickerThumbPainter(def),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _catName(StickerCategory c) => switch (c) {
        StickerCategory.letters => 'Letters',
        StickerCategory.numbers => 'Numbers',
        StickerCategory.sparkle => 'Sparkle',
        StickerCategory.gems => 'Gems',
        StickerCategory.notions => 'Notions',
        StickerCategory.faces => 'Faces',
      };
}

class _StickerThumbPainter extends CustomPainter {
  _StickerThumbPainter(this.def);
  final StickerDef def;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / def.size.width;
    final sy = size.height / def.size.height;
    final s = sx < sy ? sx : sy;
    canvas.translate(
      (size.width - def.size.width * s) / 2,
      (size.height - def.size.height * s) / 2,
    );
    canvas.scale(s);
    def.paint(canvas, def.size);
  }

  @override
  bool shouldRepaint(covariant _StickerThumbPainter oldDelegate) =>
      oldDelegate.def.id != def.id;
}

class OverlayInspector extends StatelessWidget {
  const OverlayInspector({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final item = controller.selected;
    if (item == null) return const SizedBox.shrink();
    return PaperPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item is TextBoxItem ? 'Text box' : 'Sticker',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              CuteIconButton(
                icon: Icons.flip_to_front_rounded,
                tooltip: 'Bring forward',
                onTap: controller.bringForward,
                size: 40,
              ),
              CuteIconButton(
                icon: Icons.flip_to_back_rounded,
                tooltip: 'Send back',
                onTap: controller.sendBack,
                size: 40,
              ),
              CuteIconButton(
                icon: Icons.delete_rounded,
                tooltip: 'Delete',
                onTap: controller.deleteSelected,
                size: 40,
              ),
              if (item is TextBoxItem)
                CuteIconButton(
                  icon: Icons.edit_note_rounded,
                  tooltip: 'Edit text',
                  size: 40,
                  onTap: () async {
                    final next = await promptText(
                      context,
                      title: 'Edit text',
                      initial: item.text,
                      maxLines: 4,
                    );
                    if (next != null) {
                      controller.updateSelectedText(text: next);
                    }
                  },
                ),
            ],
          ),
          _labeledSlider(
            'Size',
            ((item.scale - 0.25) / 5.75).clamp(0, 1),
            (v) {
              item.scale = 0.25 + v * 5.75;
              controller.touch();
            },
          ),
          _labeledSlider(
            'Spin',
            ((item.rotation + 3.14) / 6.28).clamp(0, 1),
            (v) {
              item.rotation = v * 6.28 - 3.14;
              controller.touch();
            },
          ),
          if (item is TextBoxItem) ...[
            _labeledSlider(
              'Type',
              ((item.fontSize - 16) / 72).clamp(0, 1),
              (v) {
                item.fontSize = 16 + v * 72;
                controller.touch();
              },
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final color in PetalPalette.pens)
                  ColorChip(
                    color: color,
                    selected: colorToArgb(item.color) == colorToArgb(color),
                    onTap: () => controller.updateSelectedText(color: color),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class PageStrip extends StatelessWidget {
  const PageStrip({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          height: 118,
          child: Row(
            children: [
              Expanded(
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  itemCount: controller.zine.pages.length,
                  onReorderItem: (from, to) {
                    controller.reorderPages(from, to);
                  },
                  itemBuilder: (context, i) {
                    final page = controller.zine.pages[i];
                    final selected = i == controller.pageIndex;
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(page.id),
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => controller.setPage(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 64,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: selected ? PetalColors.sky.withValues(alpha: 0.35) : PetalColors.paper,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? PetalColors.lavender : const Color(0x334A3A52),
                                width: selected ? 2.4 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: ZinePageSize.aspectRatio,
                                    child: CustomPaint(
                                      painter: ZinePainter(
                                        page: page,
                                        showSelection: false,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${i + 1}',
                                  style: const TextStyle(fontSize: 11, color: PetalColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              CuteIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Add page',
                onTap: controller.addPage,
                size: 40,
              ),
              const SizedBox(width: 6),
              CuteIconButton(
                icon: Icons.remove_rounded,
                tooltip: 'Delete page',
                enabled: controller.zine.pages.length > 1,
                onTap: controller.deletePage,
                size: 40,
              ),
            ],
          ),
        );
      },
    );
  }
}
