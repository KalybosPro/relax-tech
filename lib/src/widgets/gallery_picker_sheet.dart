import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../models/relax_document_file.dart';
import '../models/relax_image_file.dart';
import '../models/relax_picker_result.dart';
import '../models/relax_video_file.dart';
import 'camera_picker_sheet.dart';
import 'document_picker_sheet.dart';

enum PickerTab { gallery, camera, documents }

class GalleryPickerSheet extends StatefulWidget {
  final bool allowImages;
  final bool allowVideos;
  final bool enableCamera;
  final bool enablePreview;
  final int maxSelection;
  final bool enableCompression;
  final bool allowDocuments;

  const GalleryPickerSheet({
    super.key,
    this.allowImages = true,
    this.allowVideos = true,
    this.enableCamera = true,
    this.enablePreview = true,
    this.maxSelection = 30,
    this.enableCompression = false,
    this.allowDocuments = true,
  });

  @override
  State<GalleryPickerSheet> createState() => _GalleryPickerSheetState();
}

class _GalleryPickerSheetState extends State<GalleryPickerSheet> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 84;

  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  final List<AssetEntity> _assets = [];
  final Map<String, AssetEntity> _selectedAssets = {};
  final List<RelaxImageFile> _capturedImages = [];
  final List<RelaxVideoFile> _capturedVideos = [];
  final List<RelaxDocumentFile> _selectedDocuments = [];
  bool _isLoading = true;
  bool _isLoadingNext = false;

  // Thumbnail cache for better performance
  final Map<String, Uint8List?> _thumbnailCache = {};
  final Map<String, bool> _thumbnailLoading = {};
  static const int _maxCacheSize = 200; // Limit cache size to prevent memory issues
  int _currentPage = 0;
  late TabController _tabController;
  PickerTab _currentTab = PickerTab.gallery;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initializeGallery();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Clear thumbnail cache to free memory
    _thumbnailCache.clear();
    _thumbnailLoading.clear();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _currentTab = PickerTab.values[_tabController.index];
      if (_currentTab == PickerTab.gallery && _albums.isEmpty) {
        _initializeGallery();
      }
    });
  }

  Future<void> _initializeGallery() async {
    setState(() => _isLoading = true);

    final filterOption = FilterOptionGroup(
      imageOption: widget.allowImages ? const FilterOption() : const FilterOption(needTitle: false),
      videoOption: widget.allowVideos ? const FilterOption() : const FilterOption(needTitle: false),
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: widget.allowImages && widget.allowVideos ? RequestType.common : widget.allowImages ? RequestType.image : RequestType.video,
      filterOption: filterOption,
      hasAll: true,
    );

    if (albums.isNotEmpty) {
      _albums = albums;
      _currentAlbum = albums.first;
      await _loadPage(reset: true);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_currentAlbum == null || _isLoadingNext) return;
    _isLoadingNext = true;

    if (reset) {
      _currentPage = 0;
      _assets.clear();
    }

    final nextAssets = await _currentAlbum!.getAssetListPaged(page: _currentPage, size: _pageSize);
    _assets.addAll(nextAssets);
    _currentPage += 1;
    _isLoadingNext = false;

    // Preload thumbnails for better performance
    _preloadThumbnails(nextAssets);

    // Check if we can load more by trying to load the next page
    final nextPageAssets = await _currentAlbum!.getAssetListPaged(page: _currentPage, size: 1);
    final canLoadMore = nextPageAssets.isNotEmpty;
    if (!canLoadMore) {
      _currentPage = -1; // Mark as no more pages
    }

    setState(() {});
  }

  void _preloadThumbnails(List<AssetEntity> assets) {
    for (final asset in assets) {
      final cacheKey = asset.id;
      if (!_thumbnailCache.containsKey(cacheKey) && _thumbnailLoading[cacheKey] != true) {
        // Check cache size limit
        if (_thumbnailCache.length >= _maxCacheSize) {
          // Remove oldest entries (simple LRU approximation)
          final keysToRemove = _thumbnailCache.keys.take(_thumbnailCache.length - _maxCacheSize + 20);
          for (final key in keysToRemove) {
            _thumbnailCache.remove(key);
            _thumbnailLoading.remove(key);
          }
        }

        _thumbnailLoading[cacheKey] = true;
        asset.thumbnailData.then((data) {
          if (mounted) {
            setState(() {
              _thumbnailCache[cacheKey] = data;
              _thumbnailLoading[cacheKey] = false;
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _thumbnailCache[cacheKey] = null;
              _thumbnailLoading[cacheKey] = false;
            });
          }
        });
      }
    }
  }

  Future<String> _compressImage(String originalPath) async {
    try {
      final compressedData = await FlutterImageCompress.compressWithFile(
        originalPath,
        quality: 85,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (compressedData != null) {
        // Save compressed data to a temporary file
        final tempDir = await getTemporaryDirectory();
        final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await compressedFile.writeAsBytes(compressedData);
        return compressedFile.path;
      }
    } catch (e) {
      // If compression fails, return original path
      debugPrint('Image compression failed: $e');
    }
    return originalPath;
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingNext || _currentPage == -1) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      _loadPage();
    }
  }

  void _onAlbumChanged(AssetPathEntity? album) {
    if (album == null || album == _currentAlbum) return;
    setState(() {
      _currentAlbum = album;
      _assets.clear();
      _currentPage = 0;
      _isLoading = true;
    });
    _loadPage(reset: true).then((_) {
      setState(() => _isLoading = false);
    });
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.containsKey(asset.id)) {
        _selectedAssets.remove(asset.id);
      } else if (_selectedAssets.length < widget.maxSelection) {
        _selectedAssets[asset.id] = asset;
      }
    });
  }

  void _onMediaCaptured(dynamic media) {
    setState(() {
      if (media is RelaxImageFile) {
        _capturedImages.add(media);
      } else if (media is RelaxVideoFile) {
        _capturedVideos.add(media);
      }
    });
  }

  void _onDocumentsSelected(List<RelaxDocumentFile> documents) {
    setState(() {
      _selectedDocuments.clear();
      _selectedDocuments.addAll(documents);
    });
  }

  Widget _buildGalleryTab() {
    return Column(
      children: [
        if (_albums.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<AssetPathEntity>(
              isExpanded: true,
              value: _currentAlbum,
              items: _albums.map((album) {
                return DropdownMenuItem(
                  value: album,
                  child: Text(album.name),
                );
              }).toList(),
              onChanged: _onAlbumChanged,
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    return _buildAssetTile(_assets[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(AssetEntity asset) {
    final cacheKey = asset.id;

    // Check if thumbnail is already cached
    if (_thumbnailCache.containsKey(cacheKey)) {
      final cachedData = _thumbnailCache[cacheKey];
      if (cachedData != null) {
        return Image.memory(
          cachedData,
          fit: BoxFit.cover,
        );
      }
      return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
    }

    // Check if thumbnail is currently loading
    if (_thumbnailLoading[cacheKey] == true) {
      return const Center(child: CircularProgressIndicator());
    }

    // Start loading thumbnail
    _thumbnailLoading[cacheKey] = true;
    asset.thumbnailData.then((data) {
      if (mounted) {
        setState(() {
          _thumbnailCache[cacheKey] = data;
          _thumbnailLoading[cacheKey] = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _thumbnailCache[cacheKey] = null;
          _thumbnailLoading[cacheKey] = false;
        });
      }
    });

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildAssetTile(AssetEntity asset) {
    final isSelected = _selectedAssets.containsKey(asset.id);
    final duration = asset.type == AssetType.video ? asset.videoDuration : Duration.zero;

    return GestureDetector(
      onTap: () => _toggleSelection(asset),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildThumbnail(asset),
          if (asset.type == AssetType.video)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _formatDuration(duration),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: isSelected ? Colors.blueAccent : Colors.black45,
              child: Text(
                isSelected ? '${_selectedAssets.keys.toList().indexOf(asset.id) + 1}' : '',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: maxHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sélectionner des médias',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${_selectedAssets.length + _capturedImages.length + _capturedVideos.length + _selectedDocuments.length}/${widget.maxSelection}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              tabs: [
                if (widget.allowImages || widget.allowVideos)
                  const Tab(text: 'Galerie'),
                if (widget.enableCamera)
                  const Tab(text: 'Caméra'),
                if (widget.allowDocuments)
                  const Tab(text: 'Documents'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  if (widget.allowImages || widget.allowVideos)
                    _buildGalleryTab(),
                  if (widget.enableCamera)
                    CameraPickerSheet(
                      allowImages: widget.allowImages,
                      allowVideos: widget.allowVideos,
                      maxSelection: widget.maxSelection,
                      onMediaCaptured: _onMediaCaptured,
                    ),
                  if (widget.allowDocuments)
                    DocumentPickerSheet(
                      maxSelection: widget.maxSelection,
                      onDocumentsSelected: _onDocumentsSelected,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop<RelaxPickerResult>(null),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_selectedAssets.isEmpty && _capturedImages.isEmpty && _capturedVideos.isEmpty && _selectedDocuments.isEmpty) ? null : _onDone,
                      child: const Text('Valider'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDone() async {
    setState(() => _isLoading = true);

    final images = <RelaxImageFile>[];
    final videos = <RelaxVideoFile>[];

    try {
      final selected = _selectedAssets.values.toList();

      for (final asset in selected) {
        final file = await asset.file;
        final path = file?.path ?? '';
        final mimeType = asset.mimeType ?? asset.type.name;
        final creationDate = asset.createDateTime;
        final thumbnailPath = null;

        if (asset.type == AssetType.video) {
          videos.add(RelaxVideoFile(
            id: asset.id,
            path: path,
            mimeType: mimeType,
            size: asset.size.width.toInt() * asset.size.height.toInt() * 4, // Approximate file size
            duration: asset.videoDuration,
            width: asset.size.width.toInt(),
            height: asset.size.height.toInt(),
            thumbnailPath: thumbnailPath,
            creationDate: creationDate,
            albumId: _currentAlbum?.id,
          ));
        } else {
          // Apply compression if enabled
          String finalPath = path;
          if (widget.enableCompression && asset.size.width > 1920) {
            // Compress large images
            finalPath = await _compressImage(path);
          }

          images.add(RelaxImageFile(
            id: asset.id,
            path: finalPath,
            mimeType: mimeType,
            size: asset.size.width.toInt() * asset.size.height.toInt() * 4, // Approximate file size
            width: asset.size.width.toInt(),
            height: asset.size.height.toInt(),
            thumbnailPath: thumbnailPath,
            creationDate: creationDate,
            albumId: _currentAlbum?.id,
          ));
        }
      }
    } catch (e) {
      // If processing fails, continue with what we have
      debugPrint('Error processing selected assets: $e');
    }

    // Add captured media
    images.addAll(_capturedImages);
    videos.addAll(_capturedVideos);

    final files = <dynamic>[];
    files.addAll(images);
    files.addAll(videos);
    files.addAll(_selectedDocuments);

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).pop(RelaxPickerResult(
        files: List.unmodifiable(files),
        images: List.unmodifiable(images),
        videos: List.unmodifiable(videos),
        documents: List.unmodifiable(_selectedDocuments),
      ));
    }
  }
}
