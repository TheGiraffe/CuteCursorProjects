import 'package:flutter/material.dart';

import '../export/pdf_export.dart';
import '../theme.dart';

class CuteIconButton extends StatelessWidget {
  const CuteIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.selected = false,
    this.enabled = true,
    this.size = 46,
    this.accent,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool selected;
  final bool enabled;
  final double size;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final pop = accent ?? PetalColors.sky;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [pop, Color.lerp(pop, PetalColors.lavender, 0.45)!],
              )
            : null,
        color: selected ? null : PetalColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? pop : const Color(0x334A3A52),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: pop.withValues(alpha: selected ? 0.35 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: !enabled
            ? PetalColors.muted.withValues(alpha: 0.4)
            : selected
                ? PetalColors.ink
                : PetalColors.ink,
        size: size * 0.48,
      ),
    );
    return Tooltip(
      message: tooltip ?? '',
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: child,
        ),
      ),
    );
  }
}

class CutePillButton extends StatelessWidget {
  const CutePillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: filled
            ? const LinearGradient(
                colors: [PetalColors.peach, PetalColors.lemon, PetalColors.mint],
              )
            : null,
        color: filled ? null : PetalColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x334A3A52)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: PetalColors.ink),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w600,
                    color: PetalColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ColorChip extends StatelessWidget {
  const ColorChip({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.size = 30,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? PetalColors.ink : const Color(0x33000000),
            width: selected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class PaperPanel extends StatelessWidget {
  const PaperPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PetalColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x33B8D8F8)),
        boxShadow: [
          BoxShadow(
            color: PetalColors.lavender.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

Future<String?> promptText(
  BuildContext context, {
  required String title,
  String? initial,
  String confirm = 'Save',
  int maxLines = 1,
}) async {
  final controller = TextEditingController(text: initial ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontFamily: 'Fredoka')),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        style: const TextStyle(fontFamily: 'Fredoka'),
        decoration: InputDecoration(
          filled: true,
          fillColor: PetalColors.cream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          style: FilledButton.styleFrom(
            backgroundColor: PetalColors.mint,
            foregroundColor: PetalColors.ink,
          ),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result;
}

Future<void> showCuteColorPicker({
  required BuildContext context,
  required Color color,
  required ValueChanged<Color> onPicked,
}) async {
  var current = HSVColor.fromColor(color);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: PetalColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pick a color',
                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 20),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: current.toColor(),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x22000000)),
                  ),
                ),
                const SizedBox(height: 8),
                _slider('Hue', current.hue / 360, (v) {
                  setState(() => current = current.withHue(v * 360));
                }),
                _slider('Sat', current.saturation, (v) {
                  setState(() => current = current.withSaturation(v));
                }),
                _slider('Value', current.value, (v) {
                  setState(() => current = current.withValue(v));
                }),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: CutePillButton(
                    label: 'Use this',
                    onTap: () {
                      onPicked(current.toColor());
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<PdfExportLayout?> promptPdfLayout(BuildContext context) {
  return showDialog<PdfExportLayout>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Download PDF'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick a print layout. Fold mode pads blank pages to groups of 8 '
            '(one Letter sheet per 8 pages).',
            style: TextStyle(color: PetalColors.muted, fontSize: 13),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CutePillButton(
              label: 'One page per PDF page',
              icon: Icons.filter_none_rounded,
              onTap: () => Navigator.pop(ctx, PdfExportLayout.singlePages),
            ),
            const SizedBox(height: 8),
            CutePillButton(
              label: '8-page folded Letter',
              icon: Icons.menu_book_rounded,
              onTap: () => Navigator.pop(ctx, PdfExportLayout.foldLetter),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _slider(String label, double value, ValueChanged<double> onChanged) {
  return Row(
    children: [
      SizedBox(width: 48, child: Text(label, style: const TextStyle(fontSize: 13))),
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
