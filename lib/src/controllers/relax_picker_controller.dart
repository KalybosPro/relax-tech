import 'package:flutter/material.dart';

import '../models/relax_media_file.dart';
import '../models/relax_picker_result.dart';
import '../services/camera_service.dart';
import '../services/document_service.dart';
import '../services/gallery_service.dart';
import '../services/permission_service.dart';

class RelaxPickerController {
  final PermissionService permissionService = PermissionService();
  final GalleryService galleryService = GalleryService();
  final CameraService cameraService = CameraService();
  final DocumentService documentService = DocumentService();

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
    );

    final documentResult = allowDocuments
        ? await documentService.pickDocuments(
            acceptedTypes: acceptedDocumentTypes,
            maxSelection: maxSelection,
          )
        : null;

    final allFiles = <RelaxMediaFile>[];
    allFiles.addAll(galleryResult.files);
    if (documentResult != null) {
      allFiles.addAll(documentResult);
    }

    return RelaxPickerResult(
      files: List.unmodifiable(allFiles),
      images: List.unmodifiable(galleryResult.images),
      videos: List.unmodifiable(galleryResult.videos),
      documents: List.unmodifiable(documentResult ?? []),
    );
  }
}
