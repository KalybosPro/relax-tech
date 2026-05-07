/// Base model for a media item returned by RelaxImagePicker.
abstract class RelaxMediaFile {
  final String id;
  final String path;
  final String mimeType;
  final int size;
  final String? thumbnailPath;
  final DateTime? creationDate;

  RelaxMediaFile({
    required this.id,
    required this.path,
    required this.mimeType,
    required this.size,
    this.thumbnailPath,
    this.creationDate,
  });
}
