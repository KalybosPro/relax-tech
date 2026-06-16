import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request permissions based on the media types and features needed.
  /// 
  /// Requests gallery access for [allowImages] and [allowVideos],
  /// and camera permission for [enableCamera].
  /// 
  /// Returns true if all requested permissions are granted.
  Future<bool> requestMediaPermissions({
    bool allowImages = true,
    bool allowVideos = true,
    bool allowDocuments = true,
    bool enableCamera = true,
  }) async {
    final requiredPermissions = <Permission>[];

    // Request photo/video library access if needed
    if (allowImages || allowVideos) {
      final photoState = await PhotoManager.requestPermissionExtend();
      if (!photoState.isAuth && !photoState.isLimited) {
        return false;
      }
    }

    // Request camera permission if enabled
    if (enableCamera) {
      requiredPermissions.add(Permission.camera);
    }

    // Request microphone permission for video recording
    if (enableCamera) {
      requiredPermissions.add(Permission.microphone);
    }

    // Documents are accessed through the platform document provider
    // (Storage Access Framework on Android), which requires no runtime
    // permission on Android 13+. `allowDocuments` is intentionally not gated.

    if (requiredPermissions.isEmpty) {
      return true;
    }

    // Request all required permissions
    final statuses = await requiredPermissions.request();

    // Check if all required permissions are granted
    for (final permission in requiredPermissions) {
      if (statuses[permission] != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  /// Check if all required permissions are currently granted.
  Future<bool> checkPermissionsStatus({
    bool allowImages = true,
    bool allowVideos = true,
    bool allowDocuments = false,
    bool enableCamera = true,
  }) async {
    // Check photo/video library access
    if (allowImages || allowVideos) {
      final permissionState = await PhotoManager.requestPermissionExtend();
      if (!permissionState.isAuth && !permissionState.isLimited) {
        return false;
      }
    }

    // Check camera permission
    if (enableCamera) {
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        return false;
      }

      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        return false;
      }
    }

    // Documents use the Storage Access Framework; no runtime check needed.

    return true;
  }
}
