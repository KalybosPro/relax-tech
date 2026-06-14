import '../models/relax_document_file.dart';
import '../models/relax_image_file.dart';
import '../models/relax_video_file.dart';

class PreviewService {
  Future<void> openPreview(dynamic item) async {
    if (item is RelaxImageFile) {
      // Open fullscreen image preview.
    } else if (item is RelaxVideoFile) {
      // Open fullscreen video preview.
    } else if (item is RelaxDocumentFile) {
      // Open document preview or fallback viewer.
    }
  }
}
