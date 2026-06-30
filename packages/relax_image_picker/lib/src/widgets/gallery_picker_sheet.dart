import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/preview_item.dart';
import '../models/relax_document_file.dart';
import '../models/relax_image_file.dart';
import '../models/relax_picker_result.dart';
import '../models/relax_picker_theme.dart';
import '../models/relax_video_file.dart';
import 'camera_picker_sheet.dart';
import 'document_picker_sheet.dart';
import 'media_preview_screen.dart';

/// The two top-level views of the picker. WhatsApp keeps photos, videos and the
/// camera together in a single grid, and exposes documents as a separate view.
enum PickerView { media, documents }

/// WhatsApp-like bottom sheet that merges the gallery (photos + videos), an
/// inline camera tile and an optional documents view.
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

class _GalleryPickerSheetState extends State<GalleryPickerSheet> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 84;

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

  PickerView _view = PickerView.media;

  bool get _showMedia => widget.allowImages || widget.allowVideos;

  RelaxPickerTheme get _t => widget.theme;

  int get _totalSelected =>
      _selectedAssets.length +
      _capturedImages.length +
      _capturedVideos.length +
      _selectedDocuments.length;

  @override
  void initState() {
    super.initState();
    _view = _showMedia ? PickerView.media : PickerView.documents;
    if (_showMedia) {
      _initializeGallery();
    } else {
      _isLoading = false;
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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

    // Permission was already requested by the controller; here we only read the
    // resolved state so we know whether to show the "limited access" banner.
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

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingNext || !_hasMore) return;
    final threshold = _scrollController.position.maxScrollExtent - 400;
    if (_scrollController.position.pixels >= threshold) {
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

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.containsKey(asset.id)) {
        _selectedAssets.remove(asset.id);
      } else if (_totalSelected < widget.maxSelection) {
        _selectedAssets[asset.id] = asset;
      } else {
        _showMaxReached();
      }
    });
  }

  void _showMaxReached() {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(_t.maxSelectionLabel(widget.maxSelection))),
    );
  }

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
    if (!mounted || media == null) return;
    setState(() {
      if (media is RelaxImageFile) {
        _capturedImages.add(media);
      } else if (media is RelaxVideoFile) {
        _capturedVideos.add(media);
      }
    });
  }

  /// All currently selected items, in a stable order (gallery, captures,
  /// documents), surfaced to the shared preview.
  List<PreviewItem> _selectedPreviewItems() => [
        for (final a in _selectedAssets.values) AssetPreviewItem(a),
        for (final img in _capturedImages) CapturedImagePreviewItem(img),
        for (final vid in _capturedVideos) CapturedVideoPreviewItem(vid),
        for (final doc in _selectedDocuments) DocumentPreviewItem(doc),
      ];

  bool _isItemSelected(PreviewItem item) {
    switch (item) {
      case AssetPreviewItem(:final asset):
        return _selectedAssets.containsKey(asset.id);
      case CapturedImagePreviewItem(:final file):
        return _capturedImages.any((e) => e.id == file.id);
      case CapturedVideoPreviewItem(:final file):
        return _capturedVideos.any((e) => e.id == file.id);
      case DocumentPreviewItem(:final document):
        return _selectedDocuments.any((e) => e.path == document.path);
    }
  }

  void _toggleItem(PreviewItem item) {
    setState(() {
      switch (item) {
        case AssetPreviewItem(:final asset):
          if (_selectedAssets.containsKey(asset.id)) {
            _selectedAssets.remove(asset.id);
          } else if (_totalSelected < widget.maxSelection) {
            _selectedAssets[asset.id] = asset;
          }
        case CapturedImagePreviewItem(:final file):
          if (_capturedImages.any((e) => e.id == file.id)) {
            _capturedImages.removeWhere((e) => e.id == file.id);
          } else if (_totalSelected < widget.maxSelection) {
            _capturedImages.add(file);
          }
        case CapturedVideoPreviewItem(:final file):
          if (_capturedVideos.any((e) => e.id == file.id)) {
            _capturedVideos.removeWhere((e) => e.id == file.id);
          } else if (_totalSelected < widget.maxSelection) {
            _capturedVideos.add(file);
          }
        case DocumentPreviewItem(:final document):
          if (_selectedDocuments.any((e) => e.path == document.path)) {
            _selectedDocuments.removeWhere((e) => e.path == document.path);
          } else if (_totalSelected < widget.maxSelection) {
            _selectedDocuments.add(document);
          }
      }
    });
  }

  Future<void> _openPreview({AssetEntity? startAsset}) async {
    if (!widget.enablePreview) return;

    final selected = _selectedPreviewItems();
    final List<PreviewItem> items;
    int startIndex = 0;

    if (selected.isEmpty && startAsset != null) {
      // Long-press on an unselected tile: preview just that asset.
      items = [AssetPreviewItem(startAsset)];
    } else {
      items = selected;
      if (startAsset != null) {
        final i = items.indexWhere(
          (e) => e is AssetPreviewItem && e.asset.id == startAsset.id,
        );
        if (i >= 0) startIndex = i;
      }
    }
    if (items.isEmpty) return;

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
              creationDate: asset.createDateTime,
              albumId: _currentAlbum?.id,
            ),
          );
        } else {
          var finalPath = path;
          if (widget.enableCompression && path.isNotEmpty && asset.width > 1920) {
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
    final maxHeight =
        MediaQuery.of(context).size.height * _t.heightFactor;

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
      padding: const .symmetric(horizontal: 16.0,vertical: 4),
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

  Widget _buildAlbumSelector(ColorScheme cs) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<AssetPathEntity>(
        value: _currentAlbum,
        isDense: true,
        borderRadius: .circular(12),
        icon: Icon(_t.albumDropdownIcon, color: cs.onSurface),
        style: _t.albumTextStyle ??
            TextStyle(
              color: cs.onSurface,
              fontWeight: .w600,
              fontSize: 16,
            ),
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
          pill(widget.documentsTabText, _t.documentsTabIcon,
              PickerView.documents),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(ColorScheme cs) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: widget.theme.accentColor));
    }

    final hasCameraTile = widget.enableCamera;
    final itemCount = _assets.length + (hasCameraTile ? 1 : 0);

    final Widget grid;
    if (itemCount == 0) {
      grid = _t.emptyMediaBuilder?.call(context) ??
          Center(
            child: Text(
              _t.noMediaLabel,
              style: _t.emptyStateTitleStyle ??
                  TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          );
    } else {
      grid = _buildAssetGrid(cs, itemCount, hasCameraTile);
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
              style: _t.fileSizeTextStyle ??
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

  Widget _buildAssetGrid(ColorScheme cs, int itemCount, bool hasCameraTile) {
    return GridView.builder(
      controller: _scrollController,
      padding: const .symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (hasCameraTile && index == 0) return _buildCameraTile(cs);
        final asset = _assets[index - (hasCameraTile ? 1 : 0)];
        return _buildAssetTile(asset, cs);
      },
    );
  }

  Widget _buildCameraTile(ColorScheme cs) {
    if (_t.cameraTileBuilder != null) {
      return _t.cameraTileBuilder!(context, onTap: _openCamera);
    }
    return GestureDetector(
      onTap: _openCamera,
      child: Container(
        color: cs.onSurface.withValues(alpha: 0.06),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(_t.cameraTileIcon,
                color: widget.theme.accentColor, size: 32),
            const SizedBox(height: 6),
            Text(
              widget.cameraTabText,
              style: _t.tabTextStyle ??
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
    final isSelected = _selectedAssets.containsKey(asset.id);
    final selectionIndex =
        _selectedAssets.keys.toList().indexOf(asset.id) + 1;

    if (_t.mediaTileBuilder != null) {
      return _t.mediaTileBuilder!(
        context,
        asset: asset,
        selected: isSelected,
        selectionIndex: selectionIndex,
        isVideo: asset.type == AssetType.video,
        videoDuration: asset.videoDuration,
        thumbnail: _AssetThumbnail(key: ValueKey(asset.id), asset: asset),
        onTap: () => _toggleSelection(asset),
        onLongPress: () => _openPreview(startAsset: asset),
      );
    }

    return GestureDetector(
      onTap: () => _toggleSelection(asset),
      onLongPress: () => _openPreview(startAsset: asset),
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
                padding:
                    const .symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: .circular(12),
                ),
                child: Row(
                  children: [
                    Icon(_t.videoBadgeIcon,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      _formatDuration(asset.videoDuration),
                      style: _t.durationTextStyle ??
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
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: .circle,
                color: isSelected ? widget.theme.accentColor : Colors.black26,
                border: .all(color: Colors.white, width: 1.5),
              ),
              alignment: .center,
              child: isSelected
                  ? Text(
                      '$selectionIndex',
                      style: _t.selectionBadgeTextStyle ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                    )
                  : null,
            ),
          ),
        ],
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

class _AssetThumbnailState extends State<_AssetThumbnail> with AutomaticKeepAliveClientMixin {
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
      final data = await widget.asset
          .thumbnailDataWithSize(const ThumbnailSize.square(250));
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
    return Image.memory(
      _data!,
      fit: .cover,
      gaplessPlayback: true,
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}
