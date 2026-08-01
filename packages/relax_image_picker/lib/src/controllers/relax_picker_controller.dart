// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../models/relax_gallery_mode.dart';
import '../models/relax_picker_result.dart';
import '../models/relax_picker_theme.dart';
import '../services/camera_service.dart';
import '../services/gallery_service.dart';
import '../services/permission_service.dart';

class RelaxPickerController {
  final PermissionService permissionService = PermissionService();
  final GalleryService galleryService = GalleryService();
  final CameraService cameraService = CameraService();

  Future<RelaxPickerResult> pick(
    BuildContext context, {
    bool allowImages = true,
    bool allowVideos = true,
    bool allowDocuments = true,
    bool enableCamera = true,
    bool enablePreview = true,
    int maxSelection = 30,
    bool enableCompression = false,
    RelaxGalleryMode galleryMode = RelaxGalleryMode.systemPicker,
    List<String>? acceptedDocumentTypes,
    Color accentColor = const Color(0xFF25D366),
    RelaxPickerTheme? theme,
    required String title,
    required String confirmButtonText,
    required String cancelButtonText,
    required String validateButtonText,
    required String galleryTabText,
    required String cameraTabText,
    required String documentsTabText,
  }) async {
    // Least-privilege: we do NOT request photo-library access here. The OS
    // picker never needs it, and the in-app grid requests `READ_MEDIA_*`
    // lazily — only when its gallery view actually loads (see
    // `InAppGalleryPickerSheet._initializeGallery`). This keeps the request tied
    // to the user opening the gallery, which is what Google Play's Photo & Video
    // Permissions policy expects. Only camera/mic (for the in-app camera) are
    // requested up front.
    final permissionsGranted = await permissionService.requestMediaPermissions(
      allowImages: allowImages,
      allowVideos: allowVideos,
      enableCamera: enableCamera,
    );

    if (!permissionsGranted) {
      return RelaxPickerResult(
        files: [],
        images: [],
        videos: [],
        documents: [],
      );
    }

    final resolvedTheme = theme ?? RelaxPickerTheme(accentColor: accentColor);

    final galleryResult = await galleryService.pickFromGallery(
      context,
      allowImages: allowImages,
      allowVideos: allowVideos,
      enableCamera: enableCamera,
      enablePreview: enablePreview,
      maxSelection: maxSelection,
      enableCompression: enableCompression,
      galleryMode: galleryMode,
      accentColor: accentColor,
      theme: resolvedTheme,
      allowDocuments: allowDocuments,
      title: title,
      confirmButtonText: confirmButtonText,
      cancelButtonText: cancelButtonText,
      validateButtonText: validateButtonText,
      galleryTabText: galleryTabText,
      cameraTabText: cameraTabText,
      documentsTabText: documentsTabText,
    );

    return RelaxPickerResult(
      files: List.unmodifiable(galleryResult.files),
      images: List.unmodifiable(galleryResult.images),
      videos: List.unmodifiable(galleryResult.videos),
      documents: List.unmodifiable(galleryResult.documents),
    );
  }
}
