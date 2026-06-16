import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/preview_item.dart';
import '../models/relax_picker_theme.dart';
import 'document_thumbnail.dart';

/// Full-screen, swipeable preview of the currently selected items.
///
/// Mirrors WhatsApp's review step: swipe between items, toggle selection with
/// the corner check, and confirm with the send button. Selection changes are
/// reported live through [onToggle] so the underlying grid stays in sync.
///
/// Items can be gallery assets, in-session captures or documents — see
/// [PreviewItem].
class MediaPreviewScreen extends StatefulWidget {
  const MediaPreviewScreen({
    super.key,
    required this.items,
    required this.isSelected,
    required this.onToggle,
    required this.theme,
    this.initialIndex = 0,
    this.sendButtonText = 'Send',
  });

  final List<PreviewItem> items;
  final int initialIndex;
  final RelaxPickerTheme theme;
  final String sendButtonText;
  final bool Function(PreviewItem item) isSelected;
  final ValueChanged<PreviewItem> onToggle;

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.items.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.shrink(),
      );
    }

    final current = items[_index];
    final selected = widget.isSelected(current);
    final t = widget.theme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_index + 1} / ${items.length}'),
        actions: [
          IconButton(
            tooltip: selected ? t.deselectTooltip : t.selectTooltip,
            onPressed: () {
              widget.onToggle(current);
              setState(() {});
            },
            icon: Icon(
              selected ? t.selectedIcon : t.unselectedIcon,
              color: selected ? t.accentColor : Colors.white,
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: items.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => _PreviewPage(item: items[i], theme: t),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _label(current),
                  style: t.previewLabelTextStyle ??
                      const TextStyle(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton.icon(
                style: t.confirmButtonStyle ??
                    ElevatedButton.styleFrom(
                      backgroundColor: t.resolvedSendButtonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icon(t.sendIcon, size: 18),
                label: Text(widget.sendButtonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(PreviewItem item) {
    final t = widget.theme;
    switch (item) {
      case AssetPreviewItem(:final asset):
        return asset.type == AssetType.video
            ? '${t.videoLabel} · ${_formatDuration(asset.videoDuration)}'
            : t.photoLabel;
      case CapturedImagePreviewItem():
        return t.photoLabel;
      case CapturedVideoPreviewItem(:final file):
        return '${t.videoLabel} · ${_formatDuration(file.duration)}';
      case DocumentPreviewItem(:final document):
        return document.fileName;
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _PreviewPage extends StatelessWidget {
  const _PreviewPage({required this.item, required this.theme});

  final PreviewItem item;
  final RelaxPickerTheme theme;

  @override
  Widget build(BuildContext context) {
    switch (item) {
      case AssetPreviewItem(:final asset):
        return _AssetPage(asset: asset, theme: theme);
      case CapturedImagePreviewItem(:final file):
        return _FileImagePage(path: file.path, theme: theme);
      case CapturedVideoPreviewItem(:final file):
        return _VideoPlaceholderPage(
          label: _basename(file.path),
          theme: theme,
        );
      case DocumentPreviewItem(:final document):
        return _DocumentPage(
          path: document.path,
          extension: document.extension,
          fileName: document.fileName,
        );
    }
  }

  String _basename(String path) =>
      path.isEmpty ? '' : path.split(RegExp(r'[/\\]')).last;
}

/// Gallery asset: a fast thumbnail first, then the full-resolution file.
class _AssetPage extends StatefulWidget {
  const _AssetPage({required this.asset, required this.theme});

  final AssetEntity asset;
  final RelaxPickerTheme theme;

  @override
  State<_AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<_AssetPage> {
  File? _file;
  Uint8List? _thumb;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final thumb = await widget.asset
          .thumbnailDataWithSize(const ThumbnailSize.square(600));
      if (mounted && thumb != null) setState(() => _thumb = thumb);

      final file = await widget.asset.file;
      if (mounted) setState(() => _file = file);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.asset.type == AssetType.video;

    Widget image;
    if (_file != null && !isVideo) {
      image = Image.file(_file!, fit: BoxFit.contain);
    } else if (_thumb != null) {
      image = Image.memory(_thumb!, fit: BoxFit.contain);
    } else if (_failed) {
      image = Icon(widget.theme.brokenImageIcon,
          color: Colors.white54, size: 64);
    } else {
      image = const CircularProgressIndicator(color: Colors.white);
    }

    return _Centered(
      showPlay: isVideo,
      playIcon: widget.theme.playIcon,
      child: image,
    );
  }
}

/// In-session captured image (already a file on disk).
class _FileImagePage extends StatelessWidget {
  const _FileImagePage({required this.path, required this.theme});

  final String path;
  final RelaxPickerTheme theme;

  @override
  Widget build(BuildContext context) {
    final exists = path.isNotEmpty && File(path).existsSync();
    final broken =
        Icon(theme.brokenImageIcon, color: Colors.white54, size: 64);
    return _Centered(
      child: exists
          ? Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => broken,
            )
          : broken,
    );
  }
}

/// Captured video — no inline playback, just a clear placeholder.
class _VideoPlaceholderPage extends StatelessWidget {
  const _VideoPlaceholderPage({required this.label, required this.theme});

  final String label;
  final RelaxPickerTheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(theme.playIcon, color: Colors.white70, size: 80),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Document preview: rendered thumbnail (image / first PDF page) + name.
class _DocumentPage extends StatelessWidget {
  const _DocumentPage({
    required this.path,
    required this.extension,
    required this.fileName,
  });

  final String path;
  final String extension;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 280,
              child: DocumentThumbnail(
                path: path,
                extension: extension,
                renderSize: 440,
                iconColor: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({
    required this.child,
    this.showPlay = false,
    this.playIcon = Icons.play_circle_fill,
  });

  final Widget child;
  final bool showPlay;
  final IconData playIcon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(maxScale: 4, child: child),
          if (showPlay)
            IgnorePointer(
              child: Icon(playIcon, color: Colors.white70, size: 72),
            ),
        ],
      ),
    );
  }
}
