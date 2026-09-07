import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../export/pdf_export.dart';
import '../theme.dart';

String pdfExportBusyMessage(PdfExportLayout layout) =>
    layout == PdfExportLayout.foldLetter
        ? 'Folding your zine…'
        : 'Printing pages…';

/// Non-dismissible scrapbook overlay shown while a PDF is built and handed off.
Future<void> showPdfExportBusy(
  BuildContext context, {
  required PdfExportLayout layout,
}) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: 'PDF export',
    barrierColor: kIsWeb ? const Color(0xE64A3A52) : const Color(0xB34A3A52),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return PopScope(
        canPop: false,
        child: Center(
          child: PdfExportBusyCard(layout: layout),
        ),
      );
    },
  );
}

/// Paint the busy overlay before rasterize/PDF. Showing a dialog and then
/// immediately doing CPU work in the same turn means Flutter never gets a
/// frame to draw the loader (especially on web).
Future<void> yieldForBusyOverlayPaint() async {
  final binding = WidgetsBinding.instance;
  binding.scheduleFrame();
  await binding.endOfFrame;
  await Future<void>.delayed(Duration.zero);
  binding.scheduleFrame();
  await binding.endOfFrame;
  // Let the dialog fade-in finish, then (on web) give the scrapbook
  // animation a beat before rasterize freezes the isolate.
  await Future<void>.delayed(const Duration(milliseconds: 180));
  if (kIsWeb) {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
  binding.scheduleFrame();
  await binding.endOfFrame;
}

void hidePdfExportBusy(BuildContext context) {
  final nav = Navigator.of(context, rootNavigator: true);
  if (nav.canPop()) nav.pop();
}

class PdfExportBusyCard extends StatefulWidget {
  const PdfExportBusyCard({super.key, required this.layout});

  final PdfExportLayout layout;

  @override
  State<PdfExportBusyCard> createState() => _PdfExportBusyCardState();
}

class _PdfExportBusyCardState extends State<PdfExportBusyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFBF7),
                Color(0xFFFFF0F4),
                Color(0xFFEEF8F2),
                Color(0xFFEEF4FC),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x55D9C6F0), width: 2),
            boxShadow: [
              BoxShadow(
                color: PetalColors.lavender.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 110,
                  width: 140,
                  child: AnimatedBuilder(
                    animation: _spin,
                    builder: (context, _) => _FoldingPages(t: _spin.value),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  pdfExportBusyMessage(widget.layout),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: PetalColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hang tight — glitter takes a second.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    color: PetalColors.muted,
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

class _FoldingPages extends StatelessWidget {
  const _FoldingPages({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final pages = PetalColors.rainbow;
    return Stack(
      alignment: Alignment.center,
      children: [
        for (var i = 0; i < 4; i++)
          Transform.translate(
            offset: Offset(
              math.sin((t * math.pi * 2) + i * 0.7) * (6.0 + i * 2),
              math.cos((t * math.pi * 2) + i * 0.55) * 4 - i * 3.0,
            ),
            child: Transform.rotate(
              angle: math.sin((t * math.pi * 2) + i) * 0.18 + (i - 1.5) * 0.08,
              child: _MiniPage(color: pages[i % pages.length]),
            ),
          ),
        for (var i = 0; i < 5; i++)
          Transform.translate(
            offset: Offset(
              math.cos((t * math.pi * 2) + i * 1.25) * 52,
              math.sin((t * math.pi * 2) + i * 1.25) * 36,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 12 + (i % 3) * 3,
              color: pages[(i + 2) % pages.length].withValues(alpha: 0.9),
            ),
          ),
      ],
    );
  }
}

class _MiniPage extends StatelessWidget {
  const _MiniPage({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 70,
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, color, 0.45),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.4),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(2, 3)),
        ],
      ),
    );
  }
}
