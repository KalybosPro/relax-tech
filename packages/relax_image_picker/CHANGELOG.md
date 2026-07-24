# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-07-13

### Changed — BREAKING

- **Gallery browsing now uses the OS photo picker instead of an in-app grid.**
  The gallery is delegated to the Android Photo Picker / iOS
  `PHPickerViewController` (via `image_picker`), so the package **no longer
  requires `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`** (or `READ_EXTERNAL_STORAGE`).
  This removes Google Play's *Photo and Video Permissions policy* declaration —
  the most common media-picker rejection. Apps should delete those permissions
  from their manifest and any related Play Console declaration.
- Dropped the `photo_manager` dependency; added `image_picker`.
- The bottom sheet keeps its identity: a themed tray with a Camera tile + an
  "Add from gallery" tile that launches the OS picker, feeding the same preview /
  send / compression pipeline. All selected media is now file-based.

### Removed

- `AssetEntity`-based API: `RelaxMediaTileBuilder` now receives a
  `RelaxMediaFile media` instead of an `AssetEntity`.
- Preview items `AssetPreviewItem`, `CapturedImagePreviewItem` and
  `CapturedVideoPreviewItem` are replaced by `ImagePreviewItem` /
  `VideoPreviewItem`.
- In-app album selector, pagination and the limited-access ("Selected photos")
  banner — the OS picker owns library access and least-privilege selection.
- `RelaxPickerTheme` fields `limitedAccessLabel`, `manageAccessLabel`,
  `albumTextStyle`, `albumDropdownIcon`; added `addFromGalleryLabel` and
  `addFromGalleryIcon`.

### Notes

- Gallery-picked **videos** carry no `duration`/dimensions (the OS picker
  returns files, not library metadata); image dimensions are derived on the fly.
- The in-app camera still requires `CAMERA` (+ `RECORD_AUDIO` for sound); that is
  unaffected by the media policy.

## [1.1.0] - 2026-06-30

### Added
- Partial ("Selected photos") media access support for Android 14+ and iOS 14+:
  when the user grants access to only a subset of their library, the gallery now
  shows a banner with a **Manage** action that re-opens the system selector
  (`PhotoManager.presentLimited`) so they can widen the selection, then reloads
  the grid.
- Two customizable `RelaxPickerTheme` labels for the banner: `limitedAccessLabel`
  and `manageAccessLabel`.

### Changed
- Documented Google Play's *Photo and Video Permissions policy* in the README,
  including a ready-to-paste declaration justification, the partial-access
  requirement, and a `tools:node="remove"` snippet for stripping unwanted
  transitive media permissions.

## [1.0.1] - 2026-06-16

### Added
- Screenshots showcasing the default and custom themes, surfaced in the README
  and the pub.dev gallery.

### Changed
- Rewrote the README: documented theming and widget-slot builders, corrected the
  `pick()` return type (non-nullable `RelaxPickerResult`), and expanded the
  platform setup with minimal permission sets and store-review guidance.

## [1.0.0] - 2026-06-16

Initial release.

### Added
- WhatsApp-style media picker presented as a single bottom sheet.
- Gallery browsing with album selection and paginated, lazily-loaded media.
- In-picker camera for capturing photos and videos.
- Document selection from device storage, with optional `acceptedDocumentTypes`
  filtering and recall of recently picked documents between sessions.
- Full-screen preview step for images, videos, and documents before confirming.
- Optional on-the-fly image compression (`enableCompression`).
- Configurable selection limit (`maxSelection`) and per-type toggles
  (`allowImages`, `allowVideos`, `allowDocuments`, `enableCamera`, `enablePreview`).
- `RelaxPickerTheme` for full UI customization: accent color, surfaces and shapes,
  text and button styles, icons, and labels.
- Widget-slot builders to fully replace individual UI elements (send button,
  tabs, media/document/camera tiles, empty states, bottom bar, capture button).
- Typed results via `RelaxPickerResult` with `files`, `images`, `videos`, and
  `documents` lists plus `isEmpty` / `hasMedia` helpers.
- Media models: `RelaxMediaFile`, `RelaxImageFile`, `RelaxVideoFile`, and
  `RelaxDocumentFile` (with JSON serialization for caching).
- Permission handling for Android 13+ scoped storage and iOS limited photo access.
- Android and iOS platform support.
