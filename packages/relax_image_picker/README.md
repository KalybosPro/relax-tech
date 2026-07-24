# Relax Image Picker

## Features

- 📱 **WhatsApp-style UX** — bottom-sheet interface with smooth animations
- 🖼️ **Gallery browsing** — multi-select via the OS photo picker (no permission)
- 📷 **Camera integration** — capture photos and videos without leaving the picker
- 📄 **Document selection** — pick files from device storage, with recent-documents recall between sessions
- 👁️ **Full-screen preview** — review images, videos, and documents before confirming
- 🗜️ **Optional compression** — shrink images on the fly
- 🔒 **Permission-free gallery** — browses via the OS photo picker (Android Photo Picker / iOS `PHPickerViewController`), so no `READ_MEDIA_*` declarations and no Google Play *Photo & Video Permissions* review
- 🎨 **Deep customization** — `RelaxPickerTheme` exposes colors, text/button styles, icons, labels, and full widget-slot builders
- ⚡ **Lightweight** — no in-app library scanning; the OS returns only what the user picks

## Screenshots

| Default theme | Custom theme + builders |
|:---:|:---:|
| ![Default theme](screenshots/default_theme.png) | ![Custom theme](screenshots/custom_theme.png) |

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  relax_image_picker: ^2.0.0
```

Then run:

```sh
flutter pub get
```

### Platform setup

> **The gallery needs no media-storage permission.** Browsing is delegated to
> the OS photo picker and documents to the Storage Access Framework, so the only
> permissions you ever declare are for the optional **in-app camera**.

#### Android

Gallery browsing goes through the Android Photo Picker and documents through the
Storage Access Framework, so you **never** declare `READ_MEDIA_IMAGES`,
`READ_MEDIA_VIDEO` or `READ_EXTERNAL_STORAGE`. Only the in-app camera
(`enableCamera`) needs permissions, in
`android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Camera capture (only when enableCamera: true) -->
<uses-permission android:name="android.permission.CAMERA" />
<!-- Recording video *with sound* via the in-picker camera -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

> With `enableCamera: false`, the picker needs **zero** manifest permissions.
> The package also never requests `MANAGE_EXTERNAL_STORAGE`.

> **Legacy `READ_EXTERNAL_STORAGE`.** The `camera` dependency declares
> `WRITE_EXTERNAL_STORAGE` (`maxSdkVersion="28"`), which makes Android's manifest
> merger auto-add an *unscoped* legacy `READ_EXTERNAL_STORAGE`. It is inert on
> Android 13+ and does **not** fall under the Photo & Video Permissions policy,
> but you can scope it out of modern Android by adding this to your app manifest
> (with `xmlns:tools="http://schemas.android.com/tools"` on `<manifest>`):
>
> ```xml
> <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
>     android:maxSdkVersion="32" tools:node="replace" />
> ```

#### iOS

Gallery picking uses the system photo picker (`PHPickerViewController`), which
needs **no** `NSPhotoLibraryUsageDescription`. Only add usage strings for the
in-app camera in `ios/Runner/Info.plist`, and **make them specific** — Apple
frequently rejects vague purpose strings:

```xml
<!-- Camera capture (enableCamera) -->
<key>NSCameraUsageDescription</key>
<string>Lets you take a photo or record a video to send.</string>
<!-- Recording video with sound -->
<key>NSMicrophoneUsageDescription</key>
<string>Records sound when you capture a video.</string>
```

### Minimal permission sets

Add only the lines for the features you enable:

| Feature you use | Android | iOS |
|---|---|---|
| Gallery (`allowImages` / `allowVideos`) | *(none — OS photo picker)* | *(none — system photo picker)* |
| Documents (`allowDocuments`) | *(none — uses SAF)* | *(none — uses the system file picker)* |
| Camera photo (`enableCamera`) | `CAMERA` | `NSCameraUsageDescription` |
| Camera video with sound | `CAMERA`, `RECORD_AUDIO` | `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` |

### Store review — no media-permission gate

Because gallery browsing uses the OS photo picker, the app declares **no**
`READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`, so Google Play's *Photo and Video
Permissions policy* declaration **does not apply** — the single most common
media-picker rejection is removed entirely. The OS picker also gives the user
least-privilege, per-pick access with no in-app library scanning.

- **Apple App Store.** The camera `*UsageDescription` strings are mandatory when
  `enableCamera` is on — without them the app crashes on access. The photo
  library string is **not** required for the system picker.
- **Data safety / privacy.** Still declare any camera access in the Play *Data
  safety* form and your App Store *privacy* details.

## Usage

### Basic usage

```dart
import 'package:relax_image_picker/relax_image_picker.dart';

final result = await RelaxImagePicker.pick(context);

print('Total files: ${result.files.length}');
print('Images: ${result.images.length}');
print('Videos: ${result.videos.length}');
print('Documents: ${result.documents.length}');

for (final file in result.files) {
  print('File: ${file.path} · ${file.size} bytes');
}
```

`pick` always returns a `RelaxPickerResult`. When the user cancels or permissions
are denied, the result is empty (`result.isEmpty == true`).

### Advanced configuration

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
  accentColor: const Color(0xFF25D366),
  title: 'Select media',
);
```

### Theming

Pass a `RelaxPickerTheme` to override colors, text and button styles, icons, and
labels. Every style field is nullable and falls back to a sensible default, so an
empty `RelaxPickerTheme()` reproduces the default look.

```dart
final result = await RelaxImagePicker.pick(
  context,
  theme: RelaxPickerTheme(
    accentColor: const Color(0xFF6C4DF6),
    sheetBorderRadius: 32,
    tileBorderRadius: 18,
    titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    maxSelectionLabelBuilder: (max) => 'You can pick at most $max',
  ),
);
```

### Widget-slot builders

For full control, `RelaxPickerTheme` exposes builders that let you replace
individual widgets entirely (send button, tabs, media/document tiles, empty
states, the bottom bar, the capture button, and more). Any builder left null
falls back to the default themed widget.

```dart
RelaxPickerTheme(
  accentColor: accent,
  sendButtonBuilder: (context, {required selectedCount, required processing, required onSend}) {
    return FilledButton(
      onPressed: onSend,
      child: processing
          ? const CircularProgressIndicator(strokeWidth: 2)
          : Text('Send ($selectedCount)'),
    );
  },
);
```

See the [`example/`](example/) app for a complete demonstration mixing style
overrides and widget builders.

## API reference

### `RelaxImagePicker.pick()`

Opens the media picker with the given configuration and returns the selection.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `context` | `BuildContext` | required | Build context used to show the sheet |
| `allowImages` | `bool` | `true` | Enable image selection |
| `allowVideos` | `bool` | `true` | Enable video selection |
| `allowDocuments` | `bool` | `true` | Enable document selection |
| `enableCamera` | `bool` | `true` | Show the in-picker camera |
| `enablePreview` | `bool` | `true` | Enable the full-screen preview step |
| `maxSelection` | `int` | `30` | Maximum number of items selectable |
| `enableCompression` | `bool` | `false` | Compress images on selection |
| `acceptedDocumentTypes` | `List<String>?` | `null` | Allowed document extensions |
| `accentColor` | `Color` | `0xFF25D366` | Accent color when no `theme` is given |
| `theme` | `RelaxPickerTheme?` | `null` | Full UI customization |
| `title` | `String` | `'Select media'` | Sheet title |
| `confirmButtonText` / `cancelButtonText` / `validateButtonText` | `String` | — | Action labels |
| `galleryTabText` / `cameraTabText` / `documentsTabText` | `String` | — | Tab labels |

**Returns:** `Future<RelaxPickerResult>`

### `RelaxPickerResult`

All selected media organized by type.

| Property | Type | Description |
|---|---|---|
| `files` | `List<RelaxMediaFile>` | All selected files |
| `images` | `List<RelaxImageFile>` | Selected images only |
| `videos` | `List<RelaxVideoFile>` | Selected videos only |
| `documents` | `List<RelaxDocumentFile>` | Selected documents only |
| `isEmpty` | `bool` | `true` when nothing was selected |
| `hasMedia` | `bool` | `true` when at least one file was selected |

### Media file models

**`RelaxMediaFile`** (base) — `id`, `path`, `mimeType`, `size`, `thumbnailPath?`, `creationDate?`

- **`RelaxImageFile`** adds `width`, `height`, `albumId?`
- **`RelaxVideoFile`** adds `duration`, `width`, `height`, `isMuted`, `albumId?`
- **`RelaxDocumentFile`** adds `fileName`, `extension`, `canPreview` (plus `toJson` / `fromJson` for caching)

> **Metadata note.** The OS photo picker returns files, not library metadata.
> Image `width`/`height` are derived on the fly; gallery-picked **videos** carry
> no `duration`/dimensions (they default to `Duration.zero` / `0`). `albumId` is
> always `null` for gallery picks.

## Platform support

| Platform | Supported | Notes |
|---|---|---|
| Android | ✅ | Gallery via the Android Photo Picker (`ACTION_PICK_IMAGES`, SAF fallback ≤ API 32) — no media permission |
| iOS | ✅ | Gallery via the system photo picker (`PHPickerViewController`) — no photo-library permission |

## Architecture

```
lib/src/
├── controllers/   # Business logic and state management
├── models/        # Data models, result objects, theme & builders
├── services/      # Platform integrations (photo_manager, camera, file_picker)
├── widgets/       # UI components (gallery, camera, document pickers, preview)
└── relax_image_picker.dart  # Public API
```

## Contributing

Issues and pull requests are welcome in the
[relax-tech monorepo](https://github.com/KalybosPro/relax-tech).

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
