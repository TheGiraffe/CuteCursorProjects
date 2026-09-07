import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../persist/zine_store.dart';
import '../theme.dart';
import '../widgets/cute_chrome.dart';
import 'editor_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key, required this.store});

  final ZineStore store;

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<ZineSummary> _items = [];
  final Map<String, Uint8List> _thumbs = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.store.list();
      final thumbs = <String, Uint8List>{};
      for (final item in items) {
        final t = await widget.store.thumbnail(item.id);
        if (t != null) thumbs[item.id] = t;
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _thumbs
          ..clear()
          ..addAll(thumbs);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not open your zine shelf.';
      });
    }
  }

  Future<void> _create() async {
    final title = await promptText(
      context,
      title: 'Name your zine',
      initial: 'my tiny zine',
      confirm: 'Make it',
    );
    if (title == null || !mounted) return;
    final countRaw = await promptText(
      context,
      title: 'How many pages? (classic is 8)',
      initial: '${ZinePageSize.defaultPageCount}',
      confirm: 'Open editor',
    );
    if (countRaw == null || !mounted) return;
    final count = int.tryParse(countRaw.trim()) ?? ZinePageSize.defaultPageCount;
    final zine = Zine.create(title: title.trim().isEmpty ? 'Untitled zine' : title.trim(), pageCount: count);
    await widget.store.save(zine);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(store: widget.store, zine: zine),
      ),
    );
    await _reload();
  }

  Future<void> _open(ZineSummary summary) async {
    try {
      final zine = await widget.store.load(summary.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EditorScreen(store: widget.store, zine: zine),
        ),
      );
      await _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That zine would not open.')),
      );
    }
  }

  Future<void> _rename(ZineSummary summary) async {
    final next = await promptText(
      context,
      title: 'Rename zine',
      initial: summary.title,
    );
    if (next == null) return;
    await widget.store.rename(summary.id, next.trim().isEmpty ? summary.title : next.trim());
    await _reload();
  }

  Future<void> _delete(ZineSummary summary) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recycle this zine?'),
        content: Text('“${summary.title}” will be deleted from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: PetalColors.peach,
              foregroundColor: PetalColors.ink,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.store.delete(summary.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: PetalColors.chromeGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RainbowTitle(fontSize: 34),
                const Text(
                  AppDisplay.tagline,
                  style: TextStyle(color: PetalColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 18),
                Expanded(child: _body()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [PetalColors.peach, PetalColors.lemon, PetalColors.mint, PetalColors.sky],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: PetalColors.lavender.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _create,
          backgroundColor: Colors.transparent,
          foregroundColor: PetalColors.ink,
          elevation: 0,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('New zine', style: TextStyle(fontFamily: 'Fredoka')),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: PetalColors.sky),
            SizedBox(height: 12),
            Text('Flipping through your shelf…'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: PaperPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 10),
              CutePillButton(label: 'Try again', onTap: _reload),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: PaperPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('♡', style: TextStyle(fontSize: 42)),
              const SizedBox(height: 8),
              const Text(
                'No zines yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Start a tiny 8-page book — doodle, stamp, and write. Everything stays on this phone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: PetalColors.muted),
              ),
              const SizedBox(height: 16),
              CutePillButton(label: 'Make a zine', icon: Icons.favorite, onTap: _create),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: PetalColors.mint,
      onRefresh: _reload,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          childAspectRatio: 0.72,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: _items.length,
        itemBuilder: (context, i) => _card(_items[i]),
      ),
    );
  }

  Widget _card(ZineSummary summary) {
    final thumb = _thumbs[summary.id];
    return PaperPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _open(summary),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AspectRatio(
                    aspectRatio: ZinePageSize.aspectRatio,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: PetalColors.cream,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(3, 2)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: thumb == null
                            ? const ColoredBox(color: Color(0xFFFFF6EE))
                            : Image.memory(thumb, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${summary.pageCount} pages',
                          style: const TextStyle(fontSize: 12, color: PetalColors.muted),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') _rename(summary);
                      if (value == 'delete') _delete(summary);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
