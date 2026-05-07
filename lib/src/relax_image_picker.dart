import 'package:flutter/material.dart';

import 'controllers/relax_picker_controller.dart';
import 'models/relax_picker_result.dart';

/// Public entry point for the Relax Image Picker package.
class RelaxImagePicker {
  static Future<RelaxPickerResult> pick(
    BuildContext context, {
    bool allowImages = true,
    bool allowVideos = true,
    bool allowDocuments = true,
    bool enableCamera = true,
    bool enablePreview = true,
    int maxSelection = 30,
    bool enableCompression = false,
    List<String>? acceptedDocumentTypes,
  }) async {
    final controller = RelaxPickerController();

    return controller.pick(
      context,
      allowImages: allowImages,
      allowVideos: allowVideos,
      allowDocuments: allowDocuments,
      enableCamera: enableCamera,
      enablePreview: enablePreview,
      maxSelection: maxSelection,
      enableCompression: enableCompression,
      acceptedDocumentTypes: acceptedDocumentTypes,
    );
  }
}
