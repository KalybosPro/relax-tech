import 'relax_media_file.dart';

class RelaxDocumentFile extends RelaxMediaFile {
  final String fileName;
  final String extension;
  final bool canPreview;

  RelaxDocumentFile({
    required super.id,
    required super.path,
    required super.mimeType,
    required super.size,
    required this.fileName,
    required this.extension,
    this.canPreview = false,
    super.thumbnailPath,
    super.creationDate,
  });
}
