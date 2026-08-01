import 'package:photo_manager/photo_manager.dart';

import 'relax_document_file.dart';
import 'relax_image_file.dart';
import 'relax_video_file.dart';

/// A single entry shown in the full-screen review/preview step.
///
/// Items can be file-backed (OS-picker selections, in-app camera captures,
/// documents) or a live gallery [AssetEntity] (in-app grid mode) — the preview
/// is driven by this small sealed union.
sealed class PreviewItem {
  const PreviewItem();

  /// Stable identity used for selection lookups.
  String get id;
}

/// An item still living in the device gallery (`photo_manager`), used by the
/// in-app grid mode.
class AssetPreviewItem extends PreviewItem {
  const AssetPreviewItem(this.asset);

  final AssetEntity asset;

  @override
  String get id => 'asset:${asset.id}';
}

/// A selected image (from the OS photo picker or the in-app camera).
class ImagePreviewItem extends PreviewItem {
  const ImagePreviewItem(this.file);

  final RelaxImageFile file;

  @override
  String get id => 'image:${file.id}';
}

/// A selected video (from the OS photo picker or the in-app camera).
class VideoPreviewItem extends PreviewItem {
  const VideoPreviewItem(this.file);

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
