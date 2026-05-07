import 'package:flutter/material.dart';

import '../models/relax_picker_result.dart';
import '../widgets/gallery_picker_sheet.dart';

class GalleryService {
  Future<RelaxPickerResult> pickFromGallery(
    BuildContext context, {
    bool allowImages = true,
    bool allowVideos = true,
    bool enableCamera = true,
    bool enablePreview = true,
    int maxSelection = 30,
    bool enableCompression = false,
  }) async {
    final result = await showModalBottomSheet<RelaxPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext innerContext) {
        return GalleryPickerSheet(
          allowImages: allowImages,
          allowVideos: allowVideos,
          enableCamera: enableCamera,
          enablePreview: enablePreview,
          maxSelection: maxSelection,
          enableCompression: enableCompression,
        );
      },
    );

    return result ?? RelaxPickerResult(files: [], images: [], videos: [], documents: []);
  }
}
