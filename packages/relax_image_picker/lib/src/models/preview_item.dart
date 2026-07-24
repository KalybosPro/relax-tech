import 'relax_document_file.dart';
import 'relax_image_file.dart';
import 'relax_video_file.dart';

/// A single entry shown in the full-screen review/preview step.
///
/// Every selected item is now a file on disk — picked through the OS photo
/// picker, captured with the in-app camera or chosen from documents — so the
/// preview is driven by this small sealed union of file-backed types.
sealed class PreviewItem {
  const PreviewItem();

  /// Stable identity used for selection lookups.
  String get id;
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
