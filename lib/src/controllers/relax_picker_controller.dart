// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../models/relax_picker_result.dart';
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
    List<String>? acceptedDocumentTypes,
    required String title,
    required String confirmButtonText,
    required String cancelButtonText,
    required String validateButtonText,
    required String galleryTabText,
    required String cameraTabText,
    required String documentsTabText,
  }) async {
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

    final galleryResult = await galleryService.pickFromGallery(
      context,
      allowImages: allowImages,
      allowVideos: allowVideos,
      enableCamera: enableCamera,
      enablePreview: enablePreview,
      maxSelection: maxSelection,
      enableCompression: enableCompression,
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
