import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request the permissions the enabled features need.
  ///
  /// - Gallery browsing in `systemPicker` mode and documents go through the OS
  ///   picker / Storage Access Framework, so they need **no** runtime
  ///   permission.
  /// - The **in-app grid** gallery mode reads the whole library, so it needs
  ///   photo-library access — request it by setting [requestPhotoLibrary].
  /// - The in-app camera needs camera + microphone.
  ///
  /// Returns true if all requested permissions are granted.
  Future<bool> requestMediaPermissions({
    bool allowImages = true,
    bool allowVideos = true,
    bool allowDocuments = true,
    bool enableCamera = true,
    bool requestPhotoLibrary = false,
  }) async {
    // In-app grid mode: photo/video library access is mandatory.
    if (requestPhotoLibrary && (allowImages || allowVideos)) {
      final photoState = await PhotoManager.requestPermissionExtend();
      if (!photoState.isAuth && !photoState.isLimited) return false;
    }

    if (!enableCamera) return true;

    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return statuses[Permission.camera] == PermissionStatus.granted &&
        statuses[Permission.microphone] == PermissionStatus.granted;
  }

  /// Check whether the permissions needed by the enabled features are granted.
  Future<bool> checkPermissionsStatus({
    bool allowImages = true,
    bool allowVideos = true,
    bool allowDocuments = false,
    bool enableCamera = true,
    bool requestPhotoLibrary = false,
  }) async {
    if (requestPhotoLibrary && (allowImages || allowVideos)) {
      final permissionState = await PhotoManager.requestPermissionExtend();
      if (!permissionState.isAuth && !permissionState.isLimited) return false;
    }

    if (!enableCamera) return true;

    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) return false;

    final micStatus = await Permission.microphone.status;
    return micStatus.isGranted;
  }
}
