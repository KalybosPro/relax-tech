import 'relax_media_file.dart';

class RelaxImageFile extends RelaxMediaFile {
  final int width;
  final int height;
  final String? albumId;

  RelaxImageFile({
    required super.id,
    required super.path,
    required super.mimeType,
    required super.size,
    this.width = 0,
    this.height = 0,
    super.thumbnailPath,
    super.creationDate,
    this.albumId,
  });
}
