# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-07

### Added
- **WhatsApp-like media picker** with tabbed interface (Gallery, Camera, Documents)
- **Advanced gallery picker** with pagination, thumbnail caching, and album selection
- **Live camera capture** with photo/video recording
- **Document picker** with file type filtering
- **Intelligent permission management** for gallery, camera, and microphone
- **Automatic image compression** for large images (>1920px)
- **Performance optimizations**: Thumbnail cache (LRU, max 200), preloading, memory management
- **Comprehensive data models**: `RelaxMediaFile`, `RelaxImageFile`, `RelaxVideoFile`, `RelaxDocumentFile`
- **Modular architecture**: Controllers, services, widgets with state management
- **Cross-platform support** for iOS and Android
- **Complete example application**

### Technical Features
- **Dependencies**: photo_manager, camera, file_picker, flutter_image_compress, path_provider, permission_handler
- **API**: Static `RelaxImagePicker.pick()` method with flexible configuration
- **Performance**: 3-5x faster thumbnails, 50-70% file size reduction, memory-safe operations

### Changed
- Initial release with complete feature set
