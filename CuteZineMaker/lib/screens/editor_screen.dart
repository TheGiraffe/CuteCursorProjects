import 'package:flutter/material.dart';

import '../editor/editor_controller.dart';
import '../export/pdf_export.dart';
import '../layout.dart';
import '../models/models.dart';
import '../persist/chrome_prefs.dart';
import '../persist/zine_store.dart';
import '../theme.dart';
import '../widgets/cute_chrome.dart';
import '../widgets/editor_panels.dart';
import '../widgets/pdf_export_busy.dart';
import '../widgets/zine_canvas.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.store,
    required this.zine,
  });

  final ZineStore store;
  final Zine zine;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController _controller;
  bool _exporting = false;
  bool _sideOpen = true;

  @override
  void initState() {
    super.initState();
    _controller = EditorController(zine: widget.zine, store: widget.store);
    ChromePrefs.sideToolsOpen().then((open) {
      if (mounted) setState(() => _sideOpen = open);
    });
  }

  @override
  void dispose() {
    _controller.persist();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    await _controller.persist();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _rename() async {
    final next = await promptText(
      context,
      title: 'Rename zine',
      initial: _controller.zine.title,
    );
    if (next != null) _controller.rename(next);
  }

  Future<void> _toggleSide() async {
    setState(() => _sideOpen = !_sideOpen);
    await ChromePrefs.setSideToolsOpen(_sideOpen);
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final layout = await promptPdfLayout(context);
    if (!mounted) return;
    if (layout == null) {
      setState(() => _exporting = false);
      return;
    }

    var busyShown = false;
    try {
      busyShown = true;
      showPdfExportBusy(context, layout: layout);
      await yieldForBusyOverlayPaint();
      if (!mounted) return;
      await _controller.persist();
      if (!mounted) return;
      await shareZinePdf(_controller.zine, layout: layout);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not export the PDF. Try again in a moment.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        if (busyShown) hidePdfExportBusy(context);
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: PetalColors.chromeGradient,
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = EditorLayout.isWide(constraints.biggest);
                    return Column(
                      children: [
                        _topBar(),
                        Expanded(
                          child: wide ? _wideBody() : _narrowBody(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: PageStrip(controller: _controller),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _wideBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SideToolMenu(
            controller: _controller,
            expanded: _sideOpen,
            onToggle: _toggleSide,
            options: editorToolOptions(_controller),
          ),
          const SizedBox(width: 12),
          Expanded(child: ZineCanvas(controller: _controller)),
        ],
      ),
    );
  }

  Widget _narrowBody() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ZineCanvas(controller: _controller),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToolRail(controller: _controller),
              const SizedBox(height: 8),
              editorToolOptions(_controller),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          CuteIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            accent: PetalColors.peach,
            onTap: _leave,
            size: 42,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _rename,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _controller.zine.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Page ${_controller.pageIndex + 1} of ${_controller.zine.pages.length}  ·  2.75×4.25 in',
                    style: const TextStyle(fontSize: 11, color: PetalColors.muted),
                  ),
                ],
              ),
            ),
          ),
          CuteIconButton(
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            accent: PetalColors.lemon,
            enabled: _controller.canUndo,
            onTap: _controller.undo,
            size: 42,
          ),
          const SizedBox(width: 4),
          CuteIconButton(
            icon: Icons.redo_rounded,
            tooltip: 'Redo',
            accent: PetalColors.mint,
            enabled: _controller.canRedo,
            onTap: _controller.redo,
            size: 42,
          ),
          const SizedBox(width: 4),
          CuteIconButton(
            icon: Icons.ios_share_rounded,
            tooltip: 'Export PDF',
            accent: PetalColors.sky,
            onTap: _exporting ? null : _export,
            enabled: !_exporting,
            size: 42,
          ),
        ],
      ),
    );
  }
}
