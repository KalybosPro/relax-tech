# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
