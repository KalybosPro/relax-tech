import 'relax_document_file.dart';
import 'relax_image_file.dart';
import 'relax_media_file.dart';
import 'relax_video_file.dart';

class RelaxPickerResult {
  final List<RelaxMediaFile> files;
  final List<RelaxImageFile> images;
  final List<RelaxVideoFile> videos;
  final List<RelaxDocumentFile> documents;

  RelaxPickerResult({
    required this.files,
    required this.images,
    required this.videos,
    required this.documents,
  });

  bool get isEmpty => files.isEmpty;
  bool get hasMedia => files.isNotEmpty;
}
