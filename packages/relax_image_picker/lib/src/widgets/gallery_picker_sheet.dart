import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/preview_item.dart';
import '../models/relax_document_file.dart';
import '../models/relax_image_file.dart';
import '../models/relax_media_file.dart';
import '../models/relax_picker_result.dart';
import '../models/relax_picker_theme.dart';
import '../models/relax_video_file.dart';
import 'camera_picker_sheet.dart';
import 'document_picker_sheet.dart';
import 'media_preview_screen.dart';

/// The two top-level views of the picker. WhatsApp keeps photos, videos and the
/// camera together in a single grid, and exposes documents as a separate view.
enum PickerView { media, documents }

/// WhatsApp-like bottom sheet that gathers media (photos + videos) via the OS
/// photo picker, an inline camera and an optional documents view.
///
/// Gallery browsing is delegated to the platform photo picker
/// ([ImagePicker.pickMultipleMedia] / [ImagePicker.pickMultiImage]), so the
/// package needs **no** `READ_MEDIA_*` runtime permission. Picked items land in
/// an in-sheet selection tray and share the same preview / send pipeline as
/// camera captures and documents.
class GalleryPickerSheet extends StatefulWidget {
  const GalleryPickerSheet({
    super.key,
    this.allowImages = true,
    this.allowVideos = true,
    this.enableCamera = true,
    this.enablePreview = true,
    this.maxSelection = 30,
    this.enableCompression = false,
    this.allowDocuments = true,
    required this.theme,
    required this.title,
    required this.confirmButtonText,
    required this.cancelButtonText,
    required this.validateButtonText,
    required this.galleryTabText,
    required this.cameraTabText,
    required this.documentsTabText,
  });

  final bool allowImages;
  final bool allowVideos;
  final bool enableCamera;
  final bool enablePreview;
  final int maxSelection;
  final bool enableCompression;
  final bool allowDocuments;
  final RelaxPickerTheme theme;
  final String title;
  final String confirmButtonText;
  final String cancelButtonText;
  final String validateButtonText;
  final String galleryTabText;
  final String cameraTabText;
  final String documentsTabText;

  @override
  State<GalleryPickerSheet> createState() => _GalleryPickerSheetState();
}

class _GalleryPickerSheetState extends State<GalleryPickerSheet> {
  final ImagePicker _picker = ImagePicker();

  /// Every selected media item (gallery-picked or camera-captured), in
  /// insertion order so we can show 1-based badges.
  final List<RelaxMediaFile> _media = [];
  final List<RelaxDocumentFile> _selectedDocuments = [];

  /// True while the OS photo picker is open (disables the tile / shows a
  /// spinner).
  bool _isPicking = false;
  bool _isProcessing = false;

  PickerView _view = PickerView.media;

  bool get _showMedia => widget.allowImages || widget.allowVideos;

  RelaxPickerTheme get _t => widget.theme;

  int get _totalSelected => _media.length + _selectedDocuments.length;

  @override
  void initState() {
    super.initState();
    _view = _showMedia ? PickerView.media : PickerView.documents;
  }

  // ---------------------------------------------------------------------------
  // Gallery — OS photo picker
  // ---------------------------------------------------------------------------

  /// Launches the platform photo picker and appends the selection to the tray.
  Future<void> _addFromGallery() async {
    if (_isPicking) return;
    final remaining = widget.maxSelection - _totalSelected;
    if (remaining <= 0) {
      _showMaxReached();
      return;
    }

    setState(() => _isPicking = true);
    try {
      final picked = await _launchPicker(remaining);
      for (final x in picked) {
        if (_totalSelected >= widget.maxSelection) break;
        // Skip duplicates (same file picked twice).
        if (_media.any((e) => e.path == x.path)) continue;
        final media = await _toMediaFile(x);
        if (media != null) _media.add(media);
      }
    } catch (e) {
      debugPrint('Gallery pick failed: $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  /// Picks the right OS-picker call for the enabled media types. [limit] must be
  /// > 1 for the multi-pick APIs, so a single remaining slot uses the single
  /// pickers.
  Future<List<XFile>> _launchPicker(int remaining) async {
    final imagesOnly = widget.allowImages && !widget.allowVideos;
    final videosOnly = widget.allowVideos && !widget.allowImages;

    if (imagesOnly) {
      if (remaining == 1) {
        final x = await _picker.pickImage(source: ImageSource.gallery);
        return x == null ? const [] : [x];
      }
      return _picker.pickMultiImage(limit: remaining);
    }

    // Images + videos, or videos only: pickMultipleMedia is the only multi-pick
    // API that returns videos. image_picker has no video-only multi-pick, so for
    // the videos-only case we filter the result (best effort).
    final List<XFile> media;
    if (remaining == 1) {
      final x = await _picker.pickMedia();
      media = x == null ? const [] : [x];
    } else {
      media = await _picker.pickMultipleMedia(limit: remaining);
    }
    return videosOnly ? media.where(_isVideoFile).toList() : media;
  }

  /// Converts an [XFile] to the package's file model, deriving best-effort
  /// metadata (image dimensions; videos carry no metadata from the OS picker).
  Future<RelaxMediaFile?> _toMediaFile(XFile x) async {
    final path = x.path;
    if (path.isEmpty) return null;

    final isVideo = _isVideoFile(x);
    if (isVideo) {
      return RelaxVideoFile(
        id: path,
        path: path,
        mimeType: x.mimeType ?? _inferMimeType(path, isVideo: true),
        size: await _fileSize(path),
        duration: Duration.zero,
      );
    }

    var finalPath = path;
    if (widget.enableCompression) {
      finalPath = await _compressImage(path);
    }
    final (width, height) = await _imageDimensions(finalPath);
    return RelaxImageFile(
      id: path,
      path: finalPath,
      mimeType: x.mimeType ?? _inferMimeType(finalPath, isVideo: false),
      size: await _fileSize(finalPath),
      width: width,
      height: height,
    );
  }

  bool _isVideoFile(XFile x) {
    final mime = x.mimeType;
    if (mime != null && mime.isNotEmpty) return mime.startsWith('video/');
    return _videoExtensions.contains(_extension(x.path));
  }

  static const _videoExtensions = {
    'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'm4v', 'flv', 'wmv', 'mpeg', 'mpg',
  };

  static const _mimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'bmp': 'image/bmp',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'mkv': 'video/x-matroska',
    'webm': 'video/webm',
    '3gp': 'video/3gpp',
    'm4v': 'video/x-m4v',
  };

  String _extension(String path) {
    final i = path.lastIndexOf('.');
    return i < 0 ? '' : path.substring(i + 1).toLowerCase();
  }

  String _inferMimeType(String path, {required bool isVideo}) =>
      _mimeByExtension[_extension(path)] ?? (isVideo ? 'video/*' : 'image/*');

  /// Decodes just enough of the image to read its pixel dimensions; returns
  /// (0, 0) on failure.
  Future<(int, int)> _imageDimensions(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = (image.width, image.height);
      image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return (0, 0);
    }
  }

  // ---------------------------------------------------------------------------
  // Camera
  // ---------------------------------------------------------------------------

  Future<void> _openCamera() async {
    if (_totalSelected >= widget.maxSelection) {
      _showMaxReached();
      return;
    }
    final media = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => CameraPickerSheet(
          allowImages: widget.allowImages,
          allowVideos: widget.allowVideos,
          maxSelection: widget.maxSelection,
          theme: _t,
        ),
      ),
    );
    if (!mounted || media is! RelaxMediaFile) return;
    setState(() => _media.add(media));
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void _removeMedia(RelaxMediaFile media) {
    setState(() => _media.removeWhere((e) => e.id == media.id));
  }

  void _showMaxReached() {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(_t.maxSelectionLabel(widget.maxSelection))),
    );
  }

  /// All currently selected items, in a stable order (media then documents),
  /// surfaced to the shared preview.
  List<PreviewItem> _selectedPreviewItems() => [
        for (final m in _media) _mediaPreviewItem(m),
        for (final doc in _selectedDocuments) DocumentPreviewItem(doc),
      ];

  PreviewItem _mediaPreviewItem(RelaxMediaFile m) => m is RelaxVideoFile
      ? VideoPreviewItem(m)
      : ImagePreviewItem(m as RelaxImageFile);

  bool _isItemSelected(PreviewItem item) {
    switch (item) {
      case ImagePreviewItem(:final file):
        return _media.any((e) => e.id == file.id);
      case VideoPreviewItem(:final file):
        return _media.any((e) => e.id == file.id);
      case DocumentPreviewItem(:final document):
        return _selectedDocuments.any((e) => e.path == document.path);
    }
  }

  void _toggleItem(PreviewItem item) {
    setState(() {
      switch (item) {
        case ImagePreviewItem(:final file):
          _media.any((e) => e.id == file.id)
              ? _media.removeWhere((e) => e.id == file.id)
              : _addBackIfRoom(file);
        case VideoPreviewItem(:final file):
          _media.any((e) => e.id == file.id)
              ? _media.removeWhere((e) => e.id == file.id)
              : _addBackIfRoom(file);
        case DocumentPreviewItem(:final document):
          if (_selectedDocuments.any((e) => e.path == document.path)) {
            _selectedDocuments.removeWhere((e) => e.path == document.path);
          } else if (_totalSelected < widget.maxSelection) {
            _selectedDocuments.add(document);
          }
      }
    });
  }

  void _addBackIfRoom(RelaxMediaFile media) {
    if (_totalSelected < widget.maxSelection) _media.add(media);
  }

  Future<void> _openPreview({RelaxMediaFile? startMedia}) async {
    if (!widget.enablePreview) return;

    final items = _selectedPreviewItems();
    if (items.isEmpty) return;

    var startIndex = 0;
    if (startMedia != null) {
      final i = items.indexWhere((e) =>
          (e is ImagePreviewItem && e.file.id == startMedia.id) ||
          (e is VideoPreviewItem && e.file.id == startMedia.id));
      if (i >= 0) startIndex = i;
    }

    final shouldSend = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MediaPreviewScreen(
          items: items,
          initialIndex: startIndex,
          theme: _t,
          sendButtonText: widget.validateButtonText,
          isSelected: _isItemSelected,
          onToggle: _toggleItem,
        ),
      ),
    );

    if (mounted) setState(() {});
    if (shouldSend == true) _onDone();
  }

  void _toggleDocument(RelaxDocumentFile doc) {
    setState(() {
      final i = _selectedDocuments.indexWhere((d) => d.path == doc.path);
      if (i >= 0) {
        _selectedDocuments.removeAt(i);
      } else if (_totalSelected < widget.maxSelection) {
        _selectedDocuments.add(doc);
      } else {
        _showMaxReached();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Result
  // ---------------------------------------------------------------------------

  Future<String> _compressImage(String originalPath) async {
    try {
      final compressedData = await FlutterImageCompress.compressWithFile(
        originalPath,
        quality: 85,
        minWidth: 1920,
        minHeight: 1080,
      );
      if (compressedData != null) {
        final tempDir = await getTemporaryDirectory();
        final compressedFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await compressedFile.writeAsBytes(compressedData);
        return compressedFile.path;
      }
    } catch (e) {
      debugPrint('Image compression failed: $e');
    }
    return originalPath;
  }

  Future<int> _fileSize(String path) async {
    try {
      return await File(path).length();
    } catch (_) {
      return 0;
    }
  }

  void _onDone() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final images = _media.whereType<RelaxImageFile>().toList();
    final videos = _media.whereType<RelaxVideoFile>().toList();
    final files = <RelaxMediaFile>[...images, ...videos, ..._selectedDocuments];

    Navigator.of(context).pop(
      RelaxPickerResult(
        files: List.unmodifiable(files),
        images: List.unmodifiable(images),
        videos: List.unmodifiable(videos),
        documents: List.unmodifiable(_selectedDocuments),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * _t.heightFactor;

    return Container(
      height: maxHeight,
      decoration: BoxDecoration(
        color: _t.backgroundColor ?? cs.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_t.sheetBorderRadius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _t.dragHandleColor ??
                      cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: .circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildHeader(theme, cs),
            if (_showMedia && widget.allowDocuments) _buildViewToggle(cs),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(cs)),
            _buildBottomBar(theme, cs),
          ],
        ),
      ),
    );
  }

  /// Media grid and document view live side by side in an [IndexedStack] so
  /// switching tabs keeps each view's state (loaded documents, scroll, …)
  /// instead of rebuilding it from scratch.
  Widget _buildBody(ColorScheme cs) {
    if (!widget.allowDocuments) return _buildMediaGrid(cs);
    if (!_showMedia) return _buildDocumentView();
    return IndexedStack(
      index: _view == PickerView.media ? 0 : 1,
      children: [
        _buildMediaGrid(cs),
        _buildDocumentView(),
      ],
    );
  }

  Widget _buildDocumentView() {
    return DocumentPickerSheet(
      maxSelection: widget.maxSelection,
      theme: _t,
      selectedPaths: {for (final d in _selectedDocuments) d.path},
      onToggle: _toggleDocument,
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const .symmetric(horizontal: 16.0, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: _t.titleTextStyle ?? theme.textTheme.titleMedium,
              overflow: .ellipsis,
            ),
          ),
          if (_totalSelected > 0)
            Padding(
              padding: const .only(left: 8),
              child: Text(
                '$_totalSelected/${widget.maxSelection}',
                style: _t.counterTextStyle ??
                    theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(ColorScheme cs) {
    Widget pill(String label, IconData icon, PickerView view) {
      final selected = _view == view;
      void onTap() => setState(() => _view = view);
      if (_t.tabBuilder != null) {
        return Expanded(
          child: _t.tabBuilder!(
            context,
            label: label,
            icon: icon,
            selected: selected,
            onTap: onTap,
          ),
        );
      }
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const .symmetric(horizontal: 4),
            padding: const .symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? widget.theme.accentColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: .circular(20),
            ),
            child: Row(
              mainAxisAlignment: .center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? widget.theme.accentColor : cs.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: (_t.tabTextStyle ?? const TextStyle()).copyWith(
                    color: selected ? widget.theme.accentColor : cs.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const .fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          pill(widget.galleryTabText, _t.galleryTabIcon, PickerView.media),
          pill(widget.documentsTabText, _t.documentsTabIcon,
              PickerView.documents),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(ColorScheme cs) {
    final tiles = <Widget>[
      if (widget.enableCamera) _buildCameraTile(cs),
      _buildAddFromGalleryTile(cs),
      for (final m in _media) _buildMediaTile(m, cs),
    ];

    return GridView.builder(
      padding: const .symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) => tiles[index],
    );
  }

  Widget _buildCameraTile(ColorScheme cs) {
    if (_t.cameraTileBuilder != null) {
      return _t.cameraTileBuilder!(context, onTap: _openCamera);
    }
    return _EntryTile(
      icon: _t.cameraTileIcon,
      label: widget.cameraTabText,
      accentColor: widget.theme.accentColor,
      textStyle: _t.tabTextStyle,
      onTap: _openCamera,
    );
  }

  Widget _buildAddFromGalleryTile(ColorScheme cs) {
    return _EntryTile(
      icon: _t.addFromGalleryIcon,
      label: _t.addFromGalleryLabel,
      accentColor: widget.theme.accentColor,
      textStyle: _t.tabTextStyle,
      busy: _isPicking,
      onTap: _isPicking ? null : _addFromGallery,
    );
  }

  Widget _buildMediaTile(RelaxMediaFile media, ColorScheme cs) {
    final isVideo = media is RelaxVideoFile;
    final selectionIndex = _media.indexWhere((e) => e.id == media.id) + 1;
    final thumbnail = _mediaThumbnail(media, cs);

    if (_t.mediaTileBuilder != null) {
      return _t.mediaTileBuilder!(
        context,
        media: media,
        selected: true,
        selectionIndex: selectionIndex,
        isVideo: isVideo,
        videoDuration: isVideo ? media.duration : Duration.zero,
        thumbnail: thumbnail,
        onTap: () => _removeMedia(media),
        onLongPress: () => _openPreview(startMedia: media),
      );
    }

    return GestureDetector(
      onTap: () => _removeMedia(media),
      onLongPress: () => _openPreview(startMedia: media),
      child: Stack(
        fit: .expand,
        children: [
          Padding(
            padding: const .all(10),
            child: thumbnail,
          ),
          if (isVideo && media.duration > Duration.zero)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const .symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: .circular(12),
                ),
                child: Row(
                  children: [
                    Icon(_t.videoBadgeIcon, color: Colors.white, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      _formatDuration(media.duration),
                      style: _t.durationTextStyle ??
                          const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                margin: const .all(10),
                color: widget.theme.accentColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: .circle,
                color: widget.theme.accentColor,
                border: .all(color: Colors.white, width: 1.5),
              ),
              alignment: .center,
              child: Text(
                '$selectionIndex',
                style: _t.selectionBadgeTextStyle ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Video files have no still frame from the OS picker, so they show a themed
  /// placeholder; images render straight from disk.
  Widget _mediaThumbnail(RelaxMediaFile media, ColorScheme cs) {
    if (media is RelaxVideoFile) {
      return Container(
        color: Colors.black87,
        alignment: .center,
        child: Icon(_t.playIcon, color: Colors.white70, size: 28),
      );
    }
    return Image.file(
      File(media.path),
      fit: .cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => Container(
        color: cs.onSurface.withValues(alpha: 0.05),
        child: Icon(_t.brokenImageIcon, color: Colors.grey),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, ColorScheme cs) {
    final canSend = _totalSelected > 0;

    void onCancel() => Navigator.of(context).pop<RelaxPickerResult>(null);
    final onPreview =
        (canSend && widget.enablePreview) ? () => _openPreview() : null;
    final onSend = (canSend && !_isProcessing) ? _onDone : null;

    if (_t.bottomBarBuilder != null) {
      return _t.bottomBarBuilder!(
        context,
        selectedCount: _totalSelected,
        canSend: canSend,
        processing: _isProcessing,
        previewEnabled: widget.enablePreview,
        onCancel: onCancel,
        onPreview: onPreview,
        onSend: onSend,
      );
    }

    return Container(
      padding: const .fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          _t.cancelButtonBuilder?.call(
                context,
                label: widget.cancelButtonText,
                onPressed: onCancel,
              ) ??
              TextButton(
                style: _t.cancelButtonStyle,
                onPressed: onCancel,
                child: Text(widget.cancelButtonText),
              ),
          const Spacer(),
          if (canSend && widget.enablePreview)
            _t.confirmButtonBuilder?.call(
                  context,
                  label: widget.confirmButtonText,
                  icon: _t.previewIcon,
                  onPressed: onPreview,
                ) ??
                TextButton.icon(
                  style: _t.confirmButtonStyle,
                  onPressed: onPreview,
                  icon: Icon(_t.previewIcon, size: 18),
                  label: Text(widget.confirmButtonText),
                ),
          const SizedBox(width: 8),
          _buildSendButton(canSend),
        ],
      ),
    );
  }

  Widget _buildSendButton(bool canSend) {
    if (_t.sendButtonBuilder != null) {
      return _t.sendButtonBuilder!(
        context,
        selectedCount: _totalSelected,
        processing: _isProcessing,
        onSend: (canSend && !_isProcessing) ? _onDone : null,
      );
    }
    return Stack(
      clipBehavior: .none,
      children: [
        Material(
          color: canSend
              ? _t.resolvedSendButtonColor
              : _t.sendButtonDisabledColor,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: (canSend && !_isProcessing) ? _onDone : null,
            child: SizedBox(
              width: 52,
              height: 52,
              child: _isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_t.sendIcon, color: Colors.white),
            ),
          ),
        ),
        if (canSend)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const .all(5),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: .circle,
              ),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              alignment: .center,
              child: Text(
                '$_totalSelected',
                style: _t.selectionBadgeTextStyle?.copyWith(
                      color: widget.theme.accentColor,
                    ) ??
                    TextStyle(
                      color: widget.theme.accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// A square entry tile (camera / add-from-gallery) shown at the head of the
/// media grid.
class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
    this.textStyle,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;
  final TextStyle? textStyle;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: cs.onSurface.withValues(alpha: 0.06),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            if (busy)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: accentColor),
              )
            else
              Icon(icon, color: accentColor, size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: textStyle ??
                  TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
