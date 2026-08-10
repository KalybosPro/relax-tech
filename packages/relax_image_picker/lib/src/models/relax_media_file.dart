/// Base model for a media item returned by RelaxImagePicker.
abstract class RelaxMediaFile {
  final String id;
  final String path;
  final String mimeType;
  final int size;

  /// A still image on disk representing this file, when one is needed and can
  /// be produced.
  ///
  /// Populated for **videos picked from the device library**
  /// (`RelaxGalleryMode.inAppGrid`), whose [path] is a movie file that a caller
  /// can't render directly. Null otherwise:
  /// * images — [path] already is the picture;
  /// * camera captures and OS-picker results — no library thumbnail exists and
  ///   the package doesn't decode video frames itself.
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
