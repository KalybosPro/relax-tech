> [!IMPORTANT]
> ## 📦 This repository has moved
> `relax_image_picker` is now developed in the **[KalybosPro/relax-tech](https://github.com/KalybosPro/relax-tech)** monorepo, together with the rest of the Relax packages.
>
> - 👉 **Active source:** https://github.com/KalybosPro/relax-tech/tree/main/packages/relax_image_picker
> - 🐛 **Issues & Pull Requests:** please open them in the [monorepo](https://github.com/KalybosPro/relax-tech/issues) — this repo no longer tracks them.
> - 📥 **On pub.dev:** nothing changes. `dart pub add relax_image_picker` keeps working exactly as before.
>
> This repository is **archived** for historical reference and will not receive further updates.

---

<!-- ↓↓↓ Original README kept below for reference ↓↓↓ -->

# Relax Image Picker

A powerful, WhatsApp-like media picker for Flutter that combines gallery browsing, camera capture, and document selection in a unified, performant interface.

## Features

- 📱 **WhatsApp-style UX**: Bottom sheet interface with smooth animations
- 🖼️ **Gallery browsing**: Paginated media loading with album selection
- 📷 **Camera integration**: Capture photos and videos directly in the picker
- 📄 **Document selection**: Pick files from device storage
- ⚡ **High performance**: Lazy loading, thumbnail caching, and optimized scrolling
- 🔒 **Smart permissions**: Handles Android 13+ scoped storage and iOS limited access
- 🎯 **Flexible API**: Simple, declarative interface with extensive customization
- 📦 **Modular architecture**: Easy to extend and customize

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  relax_image_picker: ^1.0.0
```

## Usage

### Basic Usage

```dart
import 'package:relax_image_picker/relax_image_picker.dart';

final result = await RelaxImagePicker.pick(context);

// Access selected media
print('Total files: ${result.files.length}');
print('Images: ${result.images.length}');
print('Videos: ${result.videos.length}');
print('Documents: ${result.documents.length}');

// Process each file
for (final file in result.files) {
  print('File: ${file.path}, Size: ${file.size} bytes');
}
```

### Advanced Configuration

```dart
final result = await RelaxImagePicker.pick(
  context,
  allowImages: true,
  allowVideos: true,
  allowDocuments: true,
  enableCamera: true,
  enablePreview: true,
  maxSelection: 30,
  enableCompression: false,
  acceptedDocumentTypes: ['pdf', 'doc', 'docx'],
);
```

## API Reference

### RelaxImagePicker.pick()

Opens the media picker with the specified configuration.

**Parameters:**
- `context`: BuildContext (required)
- `allowImages`: bool - Enable image selection (default: true)
- `allowVideos`: bool - Enable video selection (default: true)
- `allowDocuments`: bool - Enable document selection (default: true)
- `enableCamera`: bool - Show camera tab (default: true)
- `enablePreview`: bool - Enable media preview (default: true)
- `maxSelection`: int - Maximum number of items to select (default: 30)
- `enableCompression`: bool - Compress images/videos (default: false)
- `acceptedDocumentTypes`: List<String>? - Allowed file extensions

**Returns:** `Future<RelaxPickerResult?>`

### RelaxPickerResult

Contains all selected media organized by type.

**Properties:**
- `files`: List<RelaxMediaFile> - All selected files
- `images`: List<RelaxImageFile> - Selected images only
- `videos`: List<RelaxVideoFile> - Selected videos only
- `documents`: List<RelaxDocumentFile> - Selected documents only

### Media File Models

#### RelaxMediaFile (base class)
- `id`: String - Unique identifier
- `path`: String - File system path
- `mimeType`: String - MIME type
- `size`: int - File size in bytes
- `thumbnailPath`: String? - Path to thumbnail (if available)
- `creationDate`: DateTime? - File creation date

#### RelaxImageFile extends RelaxMediaFile
- `width`: int - Image width
- `height`: int - Image height
- `albumId`: String? - Album identifier

#### RelaxVideoFile extends RelaxMediaFile
- `duration`: Duration - Video duration
- `width`: int - Video width
- `height`: int - Video height
- `isMuted`: bool - Whether video is muted
- `albumId`: String? - Album identifier

#### RelaxDocumentFile extends RelaxMediaFile
- `fileName`: String - Display name
- `extension`: String - File extension
- `canPreview`: bool - Whether file can be previewed

## Platform Support

### Android
- **Permissions**: Photos, Videos, Storage, Camera
- **Android 13+**: Scoped storage with granular permissions
- **Legacy**: Full storage access for older versions

### iOS
- **Permissions**: Photo Library, Camera
- **iOS 14+**: Limited photo library access
- **Fallback**: Graceful handling of permission denials

## Performance Optimizations

- **Lazy Loading**: Media loaded in pages of 84 items
- **Thumbnail Caching**: Efficient memory management for previews
- **Pagination**: Smooth scrolling through thousands of items
- **Background Processing**: Non-blocking file operations
- **Memory Management**: Automatic cleanup of unused resources

## Architecture

The package follows a modular architecture:

```
lib/src/
├── controllers/     # Business logic and state management
├── models/         # Data models and result objects
├── services/       # Platform integrations (photo_manager, camera, file_picker)
├── widgets/        # UI components (gallery, camera, document pickers)
└── relax_image_picker.dart  # Public API
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.