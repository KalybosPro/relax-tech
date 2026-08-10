import 'package:flutter/material.dart';

import 'controllers/relax_picker_controller.dart';
import 'models/relax_gallery_mode.dart';
import 'models/relax_picker_result.dart';
import 'models/relax_picker_theme.dart';

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

    /// Opens straight on the live camera, with the gallery collapsed into a
    /// horizontal strip of square thumbnails at the bottom that the user drags
    /// up to reveal the usual grid (camera tile, albums, …).
    ///
    /// Requires [RelaxGalleryMode.inAppGrid] and [enableCamera]; ignored
    /// otherwise. Defaults to false — the picker opens on the grid.
    bool cameraFirst = false,

    /// How the user browses their photos/videos.
    ///
    /// [RelaxGalleryMode.systemPicker] (default) uses the OS photo picker — no
    /// permission required. [RelaxGalleryMode.inAppGrid] renders the WhatsApp-
    /// style grid inside the sheet and requires `READ_MEDIA_*` (+ a Google Play
    /// *Photo and Video Permissions* declaration).
    RelaxGalleryMode galleryMode = RelaxGalleryMode.systemPicker,
    List<String>? acceptedDocumentTypes,
    Color accentColor = const Color(0xFF25D366),

    /// Full UI customization (colors, text/button styles, icons, labels).
    /// When null, a default theme derived from [accentColor] is used.
    RelaxPickerTheme? theme,
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
      cameraFirst: cameraFirst,
      galleryMode: galleryMode,
      acceptedDocumentTypes: acceptedDocumentTypes,
      accentColor: accentColor,
      theme: theme,
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
