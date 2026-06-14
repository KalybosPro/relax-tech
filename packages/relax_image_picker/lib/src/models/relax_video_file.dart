import 'relax_media_file.dart';

class RelaxVideoFile extends RelaxMediaFile {
  final Duration duration;
  final int width;
  final int height;
  final bool isMuted;
  final String? albumId;

  RelaxVideoFile({
    required super.id,
    required super.path,
    required super.mimeType,
    required super.size,
    required this.duration,
    this.width = 0,
    this.height = 0,
    this.isMuted = false,
    super.thumbnailPath,
    super.creationDate,
    this.albumId,
  });
}
