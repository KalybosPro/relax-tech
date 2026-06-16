import 'package:photo_manager/photo_manager.dart';

import 'relax_document_file.dart';
import 'relax_image_file.dart';
import 'relax_video_file.dart';

/// A single entry shown in the full-screen review/preview step.
///
/// The picker mixes several sources — gallery assets, freshly captured
/// photos/videos and documents — so the preview is driven by this small
/// sealed union rather than a single concrete type.
sealed class PreviewItem {
  const PreviewItem();

  /// Stable identity used for selection lookups.
  String get id;
}

/// An item still living in the device gallery (`photo_manager`).
class AssetPreviewItem extends PreviewItem {
  const AssetPreviewItem(this.asset);

  final AssetEntity asset;

  @override
  String get id => 'asset:${asset.id}';
}

/// A photo captured in-session through the camera.
class CapturedImagePreviewItem extends PreviewItem {
  const CapturedImagePreviewItem(this.file);

  final RelaxImageFile file;

  @override
  String get id => 'image:${file.id}';
}

/// A video captured in-session through the camera.
class CapturedVideoPreviewItem extends PreviewItem {
  const CapturedVideoPreviewItem(this.file);

  final RelaxVideoFile file;

  @override
  String get id => 'video:${file.id}';
}

/// A picked document.
class DocumentPreviewItem extends PreviewItem {
  const DocumentPreviewItem(this.document);

  final RelaxDocumentFile document;

  @override
  String get id => 'doc:${document.path}';
}
