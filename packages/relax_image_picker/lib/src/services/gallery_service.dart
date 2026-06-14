import 'package:flutter/material.dart';

import '../models/relax_picker_result.dart';
import '../widgets/gallery_picker_sheet.dart';

class GalleryService {
  Future<RelaxPickerResult> pickFromGallery(
    BuildContext context, {
    bool allowImages = true,
    bool allowVideos = true,
    bool allowDocuments = true,
    bool enableCamera = true,
    bool enablePreview = true,
    int maxSelection = 30,
    bool enableCompression = false,
     required String title,
   required String confirmButtonText,
   required String cancelButtonText,
   required String validateButtonText,
   required String galleryTabText,
   required String cameraTabText,
  required String documentsTabText,
  }) async {
    final result = await showModalBottomSheet<RelaxPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext innerContext) {
        return GalleryPickerSheet(
          allowImages: allowImages,
          allowVideos: allowVideos,
          allowDocuments: allowDocuments,
          enableCamera: enableCamera,
          enablePreview: enablePreview,
          maxSelection: maxSelection,
          enableCompression: enableCompression,
          title: title,
          confirmButtonText: confirmButtonText,
          cancelButtonText: cancelButtonText,
          validateButtonText: validateButtonText,
          galleryTabText: galleryTabText,
          cameraTabText: cameraTabText,
          documentsTabText: documentsTabText,
        );
      },
    );

    return result ?? RelaxPickerResult(files: [], images: [], videos: [], documents: []);
  }
}
