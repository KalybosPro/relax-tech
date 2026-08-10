import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../models/preview_item.dart';
import '../models/relax_picker_theme.dart';
import 'document_thumbnail.dart';

/// Full-screen, swipeable preview of the currently selected items.
///
/// Mirrors WhatsApp's review step: swipe between items, toggle selection with
/// the corner check, and confirm with the send button. Selection changes are
/// reported live through [onToggle] so the underlying tray stays in sync.
///
/// Items can be images, videos or documents — see [PreviewItem].
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
        itemBuilder: (context, i) =>
            _PreviewPage(item: items[i], theme: t, isActive: i == _index),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _label(current),
                  style:
                      t.previewLabelTextStyle ??
                      const TextStyle(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton.icon(
                style:
                    t.confirmButtonStyle ??
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
      case ImagePreviewItem():
        return t.photoLabel;
      case VideoPreviewItem(:final file):
        return file.duration > Duration.zero
            ? '${t.videoLabel} · ${_formatDuration(file.duration)}'
            : t.videoLabel;
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
  const _PreviewPage({
    required this.item,
    required this.theme,
    required this.isActive,
  });

  final PreviewItem item;
  final RelaxPickerTheme theme;

  /// Whether this is the page currently on screen — only it may play.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    switch (item) {
      case AssetPreviewItem(:final asset):
        if (asset.type == AssetType.video) {
          return _VideoPage(
            theme: theme,
            isActive: isActive,
            fileLoader: () => asset.file,
          );
        }
        return _AssetPage(asset: asset, theme: theme);
      case ImagePreviewItem(:final file):
        return _FileImagePage(path: file.path, theme: theme);
      case VideoPreviewItem(:final file):
        return _VideoPage(theme: theme, isActive: isActive, path: file.path);
      case DocumentPreviewItem(:final document):
        return _DocumentPage(
          path: document.path,
          extension: document.extension,
          fileName: document.fileName,
        );
    }
  }
}

/// Gallery *image* (in-app grid mode): a fast thumbnail first, then the
/// full-resolution file. Video assets go to [_VideoPage] instead.
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
      final thumb = await widget.asset.thumbnailDataWithSize(
        const ThumbnailSize.square(600),
      );
      if (mounted && thumb != null) setState(() => _thumb = thumb);

      final file = await widget.asset.file;
      if (mounted) setState(() => _file = file);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (_file != null) {
      image = Image.file(_file!, fit: BoxFit.contain);
    } else if (_thumb != null) {
      image = Image.memory(_thumb!, fit: BoxFit.contain);
    } else if (_failed) {
      image = Icon(
        widget.theme.brokenImageIcon,
        color: Colors.white54,
        size: 64,
      );
    } else {
      image = const CircularProgressIndicator(color: Colors.white);
    }

    return _Centered(child: image);
  }
}

/// A picked image (already a file on disk).
class _FileImagePage extends StatelessWidget {
  const _FileImagePage({required this.path, required this.theme});

  final String path;
  final RelaxPickerTheme theme;

  @override
  Widget build(BuildContext context) {
    final exists = path.isNotEmpty && File(path).existsSync();
    final broken = Icon(theme.brokenImageIcon, color: Colors.white54, size: 64);
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

/// Plays a video file: captures come with their path, gallery assets resolve
/// theirs first ([fileLoader]).
///
/// Playback is tied to [isActive] — the page the user is actually looking at —
/// so swiping to the next item pauses this one instead of leaving a soundtrack
/// running off-screen.
class _VideoPage extends StatefulWidget {
  const _VideoPage({
    required this.theme,
    required this.isActive,
    this.path,
    this.fileLoader,
  });

  final RelaxPickerTheme theme;
  final bool isActive;

  /// Direct path, for file-backed items.
  final String? path;

  /// Resolves the file lazily, for gallery assets.
  final Future<File?> Function()? fileLoader;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive) _controller?.pause();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final path = widget.path ?? (await widget.fileLoader?.call())?.path;
      if (path == null || path.isEmpty) {
        if (mounted) setState(() => _failed = true);
        return;
      }

      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      await controller.setLooping(false);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      debugPrint('Video preview failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _showControls = true;
      } else {
        // Replay from the start once the clip has run to the end.
        if (controller.value.position >= controller.value.duration) {
          controller.seekTo(Duration.zero);
        }
        controller.play();
        _showControls = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: Icon(
          widget.theme.brokenImageIcon,
          color: Colors.white54,
          size: 64,
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          // Tapping anywhere plays/pauses; the button is the affordance for it.
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final showPlay = !value.isPlaying || _showControls;
              return IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: showPlay ? 1 : 0,
                  child: Icon(
                    value.isPlaying
                        ? widget.theme.pauseRecordingIcon
                        : widget.theme.playIcon,
                    color: Colors.white70,
                    size: 72,
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              colors: VideoProgressColors(
                playedColor: widget.theme.accentColor,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
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
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(child: InteractiveViewer(maxScale: 4, child: child));
  }
}
