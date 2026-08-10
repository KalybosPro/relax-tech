import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/preview_item.dart';
import '../models/relax_document_file.dart';
import '../models/relax_image_file.dart';
import '../models/relax_media_file.dart';
import '../models/relax_picker_result.dart';
import '../models/relax_picker_theme.dart';
import '../models/relax_video_file.dart';
import 'camera_capture_view.dart';
import 'document_picker_sheet.dart';
import 'gallery_picker_sheet.dart' show PickerView;
import 'media_preview_screen.dart';

/// The two top-level views of the picker. WhatsApp keeps photos, videos and the
/// camera together in a single grid, and exposes documents as a separate view.

/// WhatsApp-like bottom sheet that merges the gallery (photos + videos), an
/// inline camera tile and an optional documents view.
class InAppGalleryPickerSheet extends StatefulWidget {
  const InAppGalleryPickerSheet({
    super.key,
    this.allowImages = true,
    this.allowVideos = true,
    this.enableCamera = true,
    this.enablePreview = true,
    this.maxSelection = 30,
    this.enableCompression = false,
    this.allowDocuments = true,
    this.cameraFirst = false,
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

  /// Opens on the live camera instead of the grid: the preview fills the
  /// screen and the gallery becomes a horizontal strip of square thumbnails
  /// pinned at the bottom, which the user drags up to reveal the full grid.
  ///
  /// Ignored when the camera or media browsing is disabled.
  final bool cameraFirst;
  final RelaxPickerTheme theme;
  final String title;
  final String confirmButtonText;
  final String cancelButtonText;
  final String validateButtonText;
  final String galleryTabText;
  final String cameraTabText;
  final String documentsTabText;

  @override
  State<InAppGalleryPickerSheet> createState() =>
      _InAppGalleryPickerSheetState();
}

class _InAppGalleryPickerSheetState extends State<InAppGalleryPickerSheet>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 84;

  /// Camera-first layout metrics: the collapsed panel is just a drag handle
  /// plus one row of square thumbnails.
  static const double _stripTileSize = 64;
  static const double _panelHandleHeight = 26;
  static const double _collapsedPanelHeight =
      _panelHandleHeight + _stripTileSize + 12;

  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  final List<AssetEntity> _assets = [];

  /// Selection preserves insertion order so we can show 1-based badges.
  final Map<String, AssetEntity> _selectedAssets = {};
  final List<RelaxImageFile> _capturedImages = [];
  final List<RelaxVideoFile> _capturedVideos = [];
  final List<RelaxDocumentFile> _selectedDocuments = [];

  bool _isLoading = true;
  bool _isLoadingNext = false;

  /// True when the OS only granted access to a user-picked subset of the
  /// library (Android 14+ "Selected photos" / iOS limited access). In that case
  /// we surface a banner letting the user grant access to more items.
  bool _isLimited = false;
  bool _isProcessing = false;
  int _currentPage = 0;
  bool _hasMore = true;

  /// Selection bubbles stay hidden until the user long-presses a tile (or the
  /// selection is non-empty), so the grid reads as a plain gallery first.
  bool _selectionMode = false;

  // --- Camera state ---

  /// True while the camera layout is showing: from the start when
  /// [InAppGalleryPickerSheet.cameraFirst], otherwise once the user taps the
  /// camera tile. Either way the gallery strip comes with it.
  bool _cameraOpen = false;

  final DraggableScrollableController _panelController =
      DraggableScrollableController();
  final ScrollController _stripController = ScrollController();

  /// The scroll controller handed to us by [DraggableScrollableSheet]; owned by
  /// the sheet, so we only attach/detach our paging listener to it.
  ScrollController? _panelScrollController;

  /// Whether the panel shows the grid rather than the strip.
  bool _panelExpanded = false;

  /// Collapsed panel height as a fraction of the screen; recomputed on build
  /// because it depends on the bottom safe area.
  double _collapsedPanelExtent = 0.2;

  PickerView _view = PickerView.media;

  bool get _showMedia => widget.allowImages || widget.allowVideos;

  /// Camera-first only makes sense when both the camera and the media grid are
  /// available.
  bool get _isCameraFirst =>
      widget.cameraFirst && widget.enableCamera && _showMedia;

  RelaxPickerTheme get _t => widget.theme;

  int get _totalSelected =>
      _selectedAssets.length +
      _capturedImages.length +
      _capturedVideos.length +
      _selectedDocuments.length;

  /// Media-only selection count — documents have their own view and never turn
  /// the grid's selection mode on.
  int get _mediaSelectedCount =>
      _selectedAssets.length + _capturedImages.length + _capturedVideos.length;

  bool get _hasRoom => _totalSelected < widget.maxSelection;

  @override
  void initState() {
    super.initState();
    _view = _showMedia ? PickerView.media : PickerView.documents;
    _cameraOpen = _isCameraFirst;
    if (_showMedia) {
      _initializeGallery();
    } else {
      _isLoading = false;
    }
    _scrollController.addListener(_onScroll);
    _stripController.addListener(_onStripScroll);
    _panelController.addListener(_onPanelExtentChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _stripController.removeListener(_onStripScroll);
    _stripController.dispose();
    _panelController.removeListener(_onPanelExtentChanged);
    _panelController.dispose();
    _panelScrollController?.removeListener(_onPanelScroll);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Gallery loading
  // ---------------------------------------------------------------------------

  RequestType get _requestType => widget.allowImages && widget.allowVideos
      ? RequestType.common
      : widget.allowImages
      ? RequestType.image
      : RequestType.video;

  Future<void> _initializeGallery() async {
    setState(() => _isLoading = true);

    // Least-privilege: the `READ_MEDIA_*` request happens HERE — lazily, the
    // moment the gallery view first loads — not up front when the picker opens.
    // This ties the prompt to the user actually opening the in-app gallery,
    // which is what Google Play's Photo & Video Permissions policy expects.
    // `isLimited` also tells us whether to show the "limited access" banner.
    final permissionState = await PhotoManager.requestPermissionExtend();
    _isLimited = permissionState.isLimited;

    final filterOption = FilterOptionGroup(
      imageOption: const FilterOption(),
      videoOption: const FilterOption(),
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: _requestType,
      filterOption: filterOption,
      hasAll: true,
    );

    if (albums.isNotEmpty) {
      _albums = albums;
      _currentAlbum = albums.first;
      await _loadPage(reset: true);
    } else {
      _albums = [];
      _currentAlbum = null;
      _assets.clear();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// Re-opens the system "selected photos" picker so the user can widen the
  /// granted subset, then reloads the grid with the new selection. No-op on
  /// platforms/OS versions without limited access.
  Future<void> _manageLimitedAccess() async {
    await PhotoManager.presentLimited(type: _requestType);
    // The plugin caches the asset list; clear it so the newly granted items
    // show up instead of the stale subset.
    await PhotoManager.clearFileCache();
    if (mounted) await _initializeGallery();
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_currentAlbum == null || _isLoadingNext) return;
    _isLoadingNext = true;

    if (reset) {
      _currentPage = 0;
      _hasMore = true;
      _assets.clear();
    }

    final nextAssets = await _currentAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    _assets.addAll(nextAssets);
    _currentPage += 1;
    _hasMore = nextAssets.length == _pageSize;
    _isLoadingNext = false;

    if (mounted) setState(() {});
  }

  void _onScroll() => _maybeLoadMore(_scrollController, 400);

  void _onStripScroll() => _maybeLoadMore(_stripController, 600);

  void _onPanelScroll() {
    final controller = _panelScrollController;
    if (controller != null) _maybeLoadMore(controller, 400);
  }

  void _maybeLoadMore(ScrollController controller, double threshold) {
    if (!controller.hasClients || _isLoadingNext || !_hasMore) return;
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - threshold) {
      _loadPage();
    }
  }

  void _onAlbumChanged(AssetPathEntity? album) {
    if (album == null || album == _currentAlbum) return;
    setState(() {
      _currentAlbum = album;
      _isLoading = true;
    });
    _loadPage(reset: true).then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  /// Tapping a tile previews it; selection only starts on a long press, which
  /// is what reveals the selection bubbles. Once selection mode is on, taps
  /// toggle and long presses preview.
  void _onTileTap(PreviewItem item) {
    if (_selectionMode || !widget.enablePreview) {
      _toggleItem(item);
      return;
    }
    _openPreviewFor(item);
  }

  void _onTileLongPress(PreviewItem item) {
    if (_selectionMode) {
      _openPreviewFor(item);
      return;
    }
    HapticFeedback.selectionClick();
    _toggleItem(item);
  }

  /// Bubbles show while at least one media item is selected; deselecting the
  /// last one hides them again.
  void _syncSelectionMode() => _selectionMode = _mediaSelectedCount > 0;

  void _showMaxReached() {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(_t.maxSelectionLabel(widget.maxSelection))),
    );
  }

  /// Opens the camera layout in place — the live preview with the gallery strip
  /// underneath — instead of a bare full-screen camera route, so the user keeps
  /// seeing (and can keep picking) their photos while shooting.
  void _openCamera() {
    if (!_hasRoom) {
      _showMaxReached();
      return;
    }
    setState(() {
      _cameraOpen = true;
      _panelExpanded = false;
    });
  }

  /// Leaves the camera. In camera-first mode there is nothing behind it, so the
  /// picker closes instead.
  void _closeCamera() {
    if (_isCameraFirst) {
      Navigator.of(context).pop<RelaxPickerResult>(null);
      return;
    }
    setState(() {
      _cameraOpen = false;
      _panelExpanded = false;
    });
  }

  /// Adds a fresh capture to the selection (and, in camera-first mode, to the
  /// head of the thumbnail strip).
  void _onCaptured(RelaxMediaFile media) {
    if (!_hasRoom) {
      _showMaxReached();
      return;
    }
    setState(() {
      if (media is RelaxImageFile) {
        _capturedImages.add(media);
      } else if (media is RelaxVideoFile) {
        _capturedVideos.add(media);
      }
      _syncSelectionMode();
    });
  }

  /// All currently selected items, in a stable order (gallery, captures,
  /// documents), surfaced to the shared preview.
  List<PreviewItem> _selectedPreviewItems() => [
    for (final a in _selectedAssets.values) AssetPreviewItem(a),
    for (final img in _capturedImages) ImagePreviewItem(img),
    for (final vid in _capturedVideos) VideoPreviewItem(vid),
    for (final doc in _selectedDocuments) DocumentPreviewItem(doc),
  ];

  bool _isItemSelected(PreviewItem item) {
    switch (item) {
      case AssetPreviewItem(:final asset):
        return _selectedAssets.containsKey(asset.id);
      case ImagePreviewItem(:final file):
        return _capturedImages.any((e) => e.id == file.id);
      case VideoPreviewItem(:final file):
        return _capturedVideos.any((e) => e.id == file.id);
      case DocumentPreviewItem(:final document):
        return _selectedDocuments.any((e) => e.path == document.path);
    }
  }

  /// Single mutation path for every selectable item, whatever surfaced it (the
  /// grid, the camera-first strip or the preview screen).
  void _toggleItem(PreviewItem item) {
    setState(() {
      switch (item) {
        case AssetPreviewItem(:final asset):
          if (_selectedAssets.containsKey(asset.id)) {
            _selectedAssets.remove(asset.id);
          } else if (_hasRoom) {
            _selectedAssets[asset.id] = asset;
          } else {
            _showMaxReached();
          }
        case ImagePreviewItem(:final file):
          if (_capturedImages.any((e) => e.id == file.id)) {
            _capturedImages.removeWhere((e) => e.id == file.id);
          } else if (_hasRoom) {
            _capturedImages.add(file);
          } else {
            _showMaxReached();
          }
        case VideoPreviewItem(:final file):
          if (_capturedVideos.any((e) => e.id == file.id)) {
            _capturedVideos.removeWhere((e) => e.id == file.id);
          } else if (_hasRoom) {
            _capturedVideos.add(file);
          } else {
            _showMaxReached();
          }
        case DocumentPreviewItem(:final document):
          if (_selectedDocuments.any((e) => e.path == document.path)) {
            _selectedDocuments.removeWhere((e) => e.path == document.path);
          } else if (_hasRoom) {
            _selectedDocuments.add(document);
          } else {
            _showMaxReached();
          }
      }
      _syncSelectionMode();
    });
  }

  /// 1-based rank of [item] in the selection, or 0 when it isn't selected.
  int _selectionIndexOf(PreviewItem item) =>
      _selectedPreviewItems().indexWhere((e) => e.id == item.id) + 1;

  /// Previews [item]: on its own when it isn't selected, otherwise within the
  /// whole selection so the user can swipe through it.
  Future<void> _openPreviewFor(PreviewItem item) {
    final selected = _selectedPreviewItems();
    final index = selected.indexWhere((e) => e.id == item.id);
    return _showPreview(index >= 0 ? selected : [item], index >= 0 ? index : 0);
  }

  /// Previews the current selection from the start (bottom-bar action).
  Future<void> _openSelectionPreview() =>
      _showPreview(_selectedPreviewItems(), 0);

  Future<void> _showPreview(List<PreviewItem> items, int initialIndex) async {
    if (!widget.enablePreview || items.isEmpty) return;

    final shouldSend = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MediaPreviewScreen(
          items: items,
          initialIndex: initialIndex,
          theme: _t,
          sendButtonText: widget.validateButtonText,
          isSelected: _isItemSelected,
          onToggle: _toggleItem,
        ),
      ),
    );

    if (mounted) setState(_syncSelectionMode);
    if (shouldSend == true) _onDone();
  }

  void _toggleDocument(RelaxDocumentFile doc) =>
      _toggleItem(DocumentPreviewItem(doc));

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

  /// Exports the library's own thumbnail for [asset] to a JPEG in the cache and
  /// returns its path.
  ///
  /// Videos need this: their `path` is a movie file, so a caller has no way to
  /// render a still without decoding it. Images don't — their `path` already is
  /// the picture.
  Future<String?> _exportThumbnail(AssetEntity asset) async {
    try {
      final data = await asset.thumbnailDataWithSize(
        const ThumbnailSize(400, 400),
      );
      if (data == null) return null;

      final tempDir = await getTemporaryDirectory();
      // Asset ids are paths on iOS, so they can't go in a filename as-is.
      final safeId = asset.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File('${tempDir.path}/relax_thumb_$safeId.jpg');
      await file.writeAsBytes(data);
      return file.path;
    } catch (e) {
      debugPrint('Thumbnail export failed: $e');
      return null;
    }
  }

  Future<void> _onDone() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final images = <RelaxImageFile>[];
    final videos = <RelaxVideoFile>[];

    try {
      for (final asset in _selectedAssets.values) {
        final file = await asset.file;
        final path = file?.path ?? '';
        final mimeType = asset.mimeType ?? 'application/octet-stream';

        if (asset.type == AssetType.video) {
          videos.add(
            RelaxVideoFile(
              id: asset.id,
              path: path,
              mimeType: mimeType,
              size: await _fileSize(path),
              duration: asset.videoDuration,
              width: asset.width,
              height: asset.height,
              thumbnailPath: await _exportThumbnail(asset),
              creationDate: asset.createDateTime,
              albumId: _currentAlbum?.id,
            ),
          );
        } else {
          var finalPath = path;
          if (widget.enableCompression &&
              path.isNotEmpty &&
              asset.width > 1920) {
            finalPath = await _compressImage(path);
          }
          images.add(
            RelaxImageFile(
              id: asset.id,
              path: finalPath,
              mimeType: mimeType,
              size: await _fileSize(finalPath),
              width: asset.width,
              height: asset.height,
              creationDate: asset.createDateTime,
              albumId: _currentAlbum?.id,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error processing selected assets: $e');
    }

    images.addAll(_capturedImages);
    videos.addAll(_capturedVideos);

    final files = <dynamic>[...images, ...videos, ..._selectedDocuments];

    if (!mounted) return;
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
    super.build(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (_cameraOpen) return _buildCameraLayout(theme, cs);

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
                  color:
                      _t.dragHandleColor ?? cs.onSurface.withValues(alpha: 0.2),
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

  // ---------------------------------------------------------------------------
  // Camera layout
  // ---------------------------------------------------------------------------

  /// Full-screen camera with the gallery collapsed into a bottom strip. Dragging
  /// the strip up grows it into the very same grid the default layout shows
  /// (camera tile, album selector, limited-access banner…).
  ///
  /// Shown from the start with `cameraFirst: true`, and whenever the user taps
  /// the camera tile otherwise.
  Widget _buildCameraLayout(ThemeData theme, ColorScheme cs) {
    final mq = MediaQuery.of(context);
    final screenHeight = mq.size.height;
    final panelHeight = _collapsedPanelHeight + mq.padding.bottom;
    _collapsedPanelExtent = screenHeight <= 0
        ? 0.2
        : (panelHeight / screenHeight).clamp(0.1, 0.6);

    return PopScope(
      // Back steps out of the layout — panel first, then the camera itself.
      canPop: !_panelExpanded && _isCameraFirst,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_panelExpanded) {
          _collapsePanel();
        } else {
          _closeCamera();
        }
      },
      child: SizedBox(
        height: screenHeight,
        child: Material(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                // Swallows vertical drags so a swipe on the preview can't
                // dismiss the whole sheet from under the camera.
                child: GestureDetector(
                  onVerticalDragStart: (_) {},
                  onVerticalDragUpdate: (_) {},
                  onVerticalDragEnd: (_) {},
                  child: CameraCaptureView(
                    allowImages: widget.allowImages,
                    allowVideos: widget.allowVideos,
                    theme: _t,
                    bottomInset: panelHeight,
                    onClose: _closeCamera,
                    onCaptured: _onCaptured,
                  ),
                ),
              ),
              Positioned.fill(child: _buildPanelSheet(theme, cs)),
              if (_panelExpanded)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: _buildBottomBar(theme, cs),
                  ),
                )
              else if (_totalSelected > 0)
                Positioned(
                  right: 16,
                  bottom: panelHeight + 16,
                  child: _buildSendButton(true),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The draggable sheet: collapsed on the strip, expanded on the full grid.
  Widget _buildPanelSheet(ThemeData theme, ColorScheme cs) {
    return DraggableScrollableSheet(
      controller: _panelController,
      initialChildSize: _collapsedPanelExtent,
      minChildSize: _collapsedPanelExtent,
      maxChildSize: 1,
      // Two resting positions: the strip and the full grid.
      snap: true,
      builder: (context, scrollController) =>
          _buildCameraPanel(scrollController, theme, cs),
    );
  }

  /// The panel body: a strip of square thumbnails while collapsed, the full
  /// media grid once expanded. Both live in the same [CustomScrollView] so the
  /// sheet's scroll controller drives the drag either way.
  Widget _buildCameraPanel(
    ScrollController scrollController,
    ThemeData theme,
    ColorScheme cs,
  ) {
    if (!identical(scrollController, _panelScrollController)) {
      _panelScrollController?.removeListener(_onPanelScroll);
      _panelScrollController = scrollController;
      scrollController.addListener(_onPanelScroll);
    }

    final expanded = _panelExpanded;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(_t.sheetBorderRadius),
      ),
      child: ColoredBox(
        color: expanded
            ? (_t.backgroundColor ?? cs.surface)
            : Colors.black.withValues(alpha: 0.45),
        child: CustomScrollView(
          controller: scrollController,
          // Keeps the drag available even when the collapsed strip has nothing
          // to scroll, so the gesture always reaches the sheet.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildPanelHandle(cs, expanded)),
            if (!expanded)
              SliverToBoxAdapter(child: _buildStrip(cs))
            else ...[
              SliverToBoxAdapter(child: _buildHeader(theme, cs)),
              if (_isLimited)
                SliverToBoxAdapter(child: _buildLimitedAccessBanner(cs)),
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: widget.theme.accentColor,
                      ),
                    ),
                  ),
                )
              else
                _buildAssetSliverGrid(cs),
            ],
            SliverToBoxAdapter(
              // Room for the bottom bar (open) or the safe area (collapsed).
              child: SizedBox(
                height: _panelExpanded
                    ? 88 + bottomPadding
                    : 12 + bottomPadding,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelHandle(ColorScheme cs, bool expanded) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: expanded ? _collapsePanel : _expandPanel,
      child: SizedBox(
        height: _panelHandleHeight,
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: expanded
                  ? (_t.dragHandleColor ?? cs.onSurface.withValues(alpha: 0.2))
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  /// Horizontal row of small squares: fresh captures first, then the gallery.
  Widget _buildStrip(ColorScheme cs) {
    if (_isLoading) {
      return SizedBox(
        height: _stripTileSize,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.theme.accentColor,
            ),
          ),
        ),
      );
    }

    final items = _stripItems();
    if (items.isEmpty) {
      return SizedBox(
        height: _stripTileSize,
        child: Center(
          child: Text(
            _t.noMediaLabel,
            style:
                _t.emptyStateTitleStyle ??
                const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: _stripTileSize,
      child: ListView.separated(
        controller: _stripController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) => _buildStripTile(items[index], cs),
      ),
    );
  }

  /// Fresh captures, newest first — they lead both the strip and the grid so a
  /// shot never disappears the moment it is taken.
  List<PreviewItem> _capturedItems() => [
    for (final video in _capturedVideos.reversed) VideoPreviewItem(video),
    for (final image in _capturedImages.reversed) ImagePreviewItem(image),
  ];

  List<PreviewItem> _stripItems() => [
    ..._capturedItems(),
    for (final asset in _assets) AssetPreviewItem(asset),
  ];

  Widget _buildStripTile(PreviewItem item, ColorScheme cs) {
    final selected = _isItemSelected(item);
    return GestureDetector(
      onTap: () => _onTileTap(item),
      onLongPress: () => _onTileLongPress(item),
      child: SizedBox(
        width: _stripTileSize,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_t.tileBorderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _stripThumbnail(item, cs),
              if (selected) ...[
                IgnorePointer(
                  child: ColoredBox(
                    color: widget.theme.accentColor.withValues(alpha: 0.25),
                  ),
                ),
                Positioned(
                  top: 3,
                  right: 3,
                  child: _buildSelectionBadge(
                    selected: true,
                    selectionIndex: _selectionIndexOf(item),
                    size: 18,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stripThumbnail(PreviewItem item, ColorScheme cs) {
    switch (item) {
      case AssetPreviewItem(:final asset):
        return _AssetThumbnail(key: ValueKey(asset.id), asset: asset);
      case ImagePreviewItem(:final file):
        return Image.file(
          File(file.path),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => ColoredBox(
            color: cs.onSurface.withValues(alpha: 0.05),
            child: Icon(_t.brokenImageIcon, color: Colors.grey),
          ),
        );
      case VideoPreviewItem():
        return ColoredBox(
          color: Colors.black87,
          child: Center(
            child: Icon(_t.playIcon, color: Colors.white70, size: 22),
          ),
        );
      // Documents have their own view and never reach the strip.
      case DocumentPreviewItem():
        return const SizedBox.shrink();
    }
  }

  Widget _buildAssetSliverGrid(ColorScheme cs) {
    final hasCameraTile = widget.enableCamera;
    final captured = _capturedItems();
    final itemCount =
        _assets.length + captured.length + (hasCameraTile ? 1 : 0);
    if (itemCount == 0) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child:
              _t.emptyMediaBuilder?.call(context) ??
              Center(
                child: Text(
                  _t.noMediaLabel,
                  style:
                      _t.emptyStateTitleStyle ??
                      TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              _buildGridItem(index, hasCameraTile, captured, cs),
          childCount: itemCount,
        ),
      ),
    );
  }

  /// Grid order, shared by both layouts: camera tile, fresh captures, then the
  /// device gallery.
  Widget _buildGridItem(
    int index,
    bool hasCameraTile,
    List<PreviewItem> captured,
    ColorScheme cs,
  ) {
    var i = index;
    if (hasCameraTile) {
      if (i == 0) return _buildCameraTile(cs);
      i -= 1;
    }
    if (i < captured.length) return _buildCapturedTile(captured[i], cs);
    return _buildAssetTile(_assets[i - captured.length], cs);
  }

  /// A capture in the grid. It is selected by definition — deselecting it drops
  /// it (there is nowhere else for it to live).
  Widget _buildCapturedTile(PreviewItem item, ColorScheme cs) {
    final selected = _isItemSelected(item);
    return GestureDetector(
      onTap: () => _onTileTap(item),
      onLongPress: () => _onTileLongPress(item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(selected ? 10 : 0),
            child: _stripThumbnail(item, cs),
          ),
          if (selected)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(10),
                  color: widget.theme.accentColor.withValues(alpha: 0.15),
                ),
              ),
            ),
          if (_selectionMode)
            Positioned(
              top: 6,
              right: 6,
              child: _buildSelectionBadge(
                selected: selected,
                selectionIndex: selected ? _selectionIndexOf(item) : 0,
              ),
            ),
        ],
      ),
    );
  }

  void _onPanelExtentChanged() {
    if (!_panelController.isAttached) return;
    // Swap strip → grid as soon as the drag leaves the collapsed position, so
    // the panel grows into the grid under the user's finger.
    final expanded = _panelController.size > _collapsedPanelExtent + 0.08;
    if (expanded != _panelExpanded) {
      setState(() => _panelExpanded = expanded);
    }
  }

  void _collapsePanel() => _animatePanelTo(_collapsedPanelExtent);

  void _expandPanel() => _animatePanelTo(1);

  void _animatePanelTo(double extent) {
    if (!_panelController.isAttached) return;
    _panelController.animateTo(
      extent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
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
      children: [_buildMediaGrid(cs), _buildDocumentView()],
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
            child: _view == PickerView.media && _albums.isNotEmpty
                ? _buildAlbumSelector(cs)
                : Text(
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
                style:
                    _t.counterTextStyle ??
                    theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlbumSelector(ColorScheme cs) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<AssetPathEntity>(
        value: _currentAlbum,
        isDense: true,
        borderRadius: .circular(12),
        icon: Icon(_t.albumDropdownIcon, color: cs.onSurface),
        style:
            _t.albumTextStyle ??
            TextStyle(color: cs.onSurface, fontWeight: .w600, fontSize: 16),
        dropdownColor: cs.surface,
        items: _albums
            .map(
              (album) => DropdownMenuItem(
                value: album,
                child: Text(album.name, overflow: .ellipsis),
              ),
            )
            .toList(),
        onChanged: _onAlbumChanged,
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
          pill(
            widget.documentsTabText,
            _t.documentsTabIcon,
            PickerView.documents,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(ColorScheme cs) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: widget.theme.accentColor),
      );
    }

    final hasCameraTile = widget.enableCamera;
    final captured = _capturedItems();
    final itemCount =
        _assets.length + captured.length + (hasCameraTile ? 1 : 0);

    final Widget grid;
    if (itemCount == 0) {
      grid =
          _t.emptyMediaBuilder?.call(context) ??
          Center(
            child: Text(
              _t.noMediaLabel,
              style:
                  _t.emptyStateTitleStyle ??
                  TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          );
    } else {
      grid = _buildAssetGrid(cs, itemCount, hasCameraTile, captured);
    }

    // When access is limited, the grid alone can look empty or partial; the
    // banner explains why and lets the user grant access to more items.
    if (!_isLimited) return grid;
    return Column(
      children: [
        _buildLimitedAccessBanner(cs),
        Expanded(child: grid),
      ],
    );
  }

  Widget _buildLimitedAccessBanner(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.theme.accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: widget.theme.accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _t.limitedAccessLabel,
              style:
                  _t.fileSizeTextStyle ??
                  TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.8),
                  ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _manageLimitedAccess,
            style: TextButton.styleFrom(
              foregroundColor: widget.theme.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(_t.manageAccessLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetGrid(
    ColorScheme cs,
    int itemCount,
    bool hasCameraTile,
    List<PreviewItem> captured,
  ) {
    return GridView.builder(
      controller: _scrollController,
      padding: const .symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          _buildGridItem(index, hasCameraTile, captured, cs),
    );
  }

  Widget _buildCameraTile(ColorScheme cs) {
    // With the camera layout showing, the live preview is already behind the
    // panel: the tile drops back to it instead of re-opening the camera.
    final onTap = _cameraOpen ? _collapsePanel : _openCamera;
    if (_t.cameraTileBuilder != null) {
      return _t.cameraTileBuilder!(context, onTap: onTap);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: cs.onSurface.withValues(alpha: 0.06),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(_t.cameraTileIcon, color: widget.theme.accentColor, size: 32),
            const SizedBox(height: 6),
            Text(
              widget.cameraTabText,
              style:
                  _t.tabTextStyle ??
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

  Widget _buildAssetTile(AssetEntity asset, ColorScheme cs) {
    final item = AssetPreviewItem(asset);
    final isSelected = _selectedAssets.containsKey(asset.id);
    final selectionIndex = isSelected ? _selectionIndexOf(item) : 0;

    if (_t.assetTileBuilder != null) {
      return _t.assetTileBuilder!(
        context,
        asset: asset,
        selected: isSelected,
        selectionMode: _selectionMode,
        selectionIndex: selectionIndex,
        isVideo: asset.type == AssetType.video,
        videoDuration: asset.videoDuration,
        thumbnail: _AssetThumbnail(key: ValueKey(asset.id), asset: asset),
        onTap: () => _onTileTap(item),
        onLongPress: () => _onTileLongPress(item),
      );
    }

    return GestureDetector(
      onTap: () => _onTileTap(item),
      onLongPress: () => _onTileLongPress(item),
      child: Stack(
        fit: .expand,
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: .all(isSelected ? 10 : 0),
            child: _AssetThumbnail(key: ValueKey(asset.id), asset: asset),
          ),
          if (asset.type == AssetType.video)
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
                      _formatDuration(asset.videoDuration),
                      style:
                          _t.durationTextStyle ??
                          const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          if (isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: widget.theme.accentColor.withValues(alpha: 0.15),
                ),
              ),
            ),
          // Bubbles only exist in selection mode — a long press turns it on.
          if (_selectionMode)
            Positioned(
              top: 6,
              right: 6,
              child: _buildSelectionBadge(
                selected: isSelected,
                selectionIndex: selectionIndex,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionBadge({
    required bool selected,
    required int selectionIndex,
    double size = 22,
    double fontSize = 12,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? widget.theme.accentColor : Colors.black26,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: selected
          ? Text(
              '$selectionIndex',
              style:
                  _t.selectionBadgeTextStyle ??
                  TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
            )
          : null,
    );
  }

  Widget _buildBottomBar(ThemeData theme, ColorScheme cs) {
    final canSend = _totalSelected > 0;

    void onCancel() => Navigator.of(context).pop<RelaxPickerResult>(null);
    final onPreview = (canSend && widget.enablePreview)
        ? () => _openSelectionPreview()
        : null;
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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
                style:
                    _t.selectionBadgeTextStyle?.copyWith(
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

  @override
  bool get wantKeepAlive => true;
}

/// Lightweight thumbnail tile with a process-wide LRU cache.
///
/// Loading happens off the build phase (in [initState]), which avoids the
/// `setState` during build storms of the previous implementation.
class _AssetThumbnail extends StatefulWidget {
  const _AssetThumbnail({super.key, required this.asset});

  final AssetEntity asset;

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail>
    with AutomaticKeepAliveClientMixin {
  static final Map<String, Uint8List> _cache = {};
  static final List<String> _order = [];
  static const int _maxCache = 300;

  Uint8List? _data;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _AssetThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _data = null;
      _failed = false;
      _load();
    }
  }

  static void _put(String id, Uint8List data) {
    if (!_cache.containsKey(id)) _order.add(id);
    _cache[id] = data;
    while (_order.length > _maxCache) {
      _cache.remove(_order.removeAt(0));
    }
  }

  Future<void> _load() async {
    final id = widget.asset.id;
    final cached = _cache[id];
    if (cached != null) {
      setState(() => _data = cached);
      return;
    }
    try {
      final data = await widget.asset.thumbnailDataWithSize(
        const ThumbnailSize.square(250),
      );
      if (!mounted) return;
      if (data != null) {
        _put(id, data);
        setState(() => _data = data);
      } else {
        setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final placeholder = Container(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
    );
    if (_failed) {
      return Container(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    if (_data == null) return placeholder;
    return Image.memory(_data!, fit: .cover, gaplessPlayback: true);
  }

  @override
  bool get wantKeepAlive => true;
}
