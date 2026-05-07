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
    String title = 'Select media',
    String confirmButtonText = 'Confirm',
    String cancelButtonText = 'Cancel',
    String validateButtonText = 'Validate',
    String galleryTabText = 'Gallery',
    String cameraTabText = 'Camera',
    String documentsTabText = 'Documents',
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
      title: title,
      confirmButtonText: confirmButtonText,
      cancelButtonText: cancelButtonText,
      validateButtonText: validateButtonText,
      galleryTabText: galleryTabText,
      cameraTabText: cameraTabText,
      documentsTabText: documentsTabText,
    );
  }
}
