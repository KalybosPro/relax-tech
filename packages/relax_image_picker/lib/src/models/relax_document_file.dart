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

  /// Serializes the document metadata so it can be cached between sessions
  /// (see `RecentDocumentsStore`). The underlying file is *not* embedded; only
  /// its path and descriptors are stored.
  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'mimeType': mimeType,
        'size': size,
        'fileName': fileName,
        'extension': extension,
        'canPreview': canPreview,
        'thumbnailPath': thumbnailPath,
        'creationDate': creationDate?.toIso8601String(),
      };

  factory RelaxDocumentFile.fromJson(Map<String, dynamic> json) {
    final rawDate = json['creationDate'] as String?;
    return RelaxDocumentFile(
      id: json['id'] as String,
      path: json['path'] as String,
      mimeType: json['mimeType'] as String,
      size: (json['size'] as num?)?.toInt() ?? 0,
      fileName: json['fileName'] as String,
      extension: json['extension'] as String? ?? '',
      canPreview: json['canPreview'] as bool? ?? false,
      thumbnailPath: json['thumbnailPath'] as String?,
      creationDate: rawDate != null ? DateTime.tryParse(rawDate) : null,
    );
  }
}
