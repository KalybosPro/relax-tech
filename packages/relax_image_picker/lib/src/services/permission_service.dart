import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request the permissions the enabled features need.
  ///
  /// Gallery browsing goes through the OS photo picker and documents through the
  /// Storage Access Framework, so **neither needs a runtime permission**. The
  /// only permissions requested here are camera + microphone, and only when the
  /// in-app camera ([enableCamera]) is enabled.
  ///
  /// Returns true if all requested permissions are granted (always true when the
  /// camera is disabled, since nothing needs to be requested).
  Future<bool> requestMediaPermissions({
    bool allowImages = true,
    bool allowVideos = true,
    bool allowDocuments = true,
    bool enableCamera = true,
  }) async {
    if (!enableCamera) return true;

    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return statuses[Permission.camera] == PermissionStatus.granted &&
        statuses[Permission.microphone] == PermissionStatus.granted;
  }

  /// Check whether the permissions needed by the enabled features are granted.
  ///
  /// Only the camera + microphone are checked (and only when [enableCamera] is
  /// set); gallery and documents require no runtime permission.
  Future<bool> checkPermissionsStatus({
    bool allowImages = true,
    bool allowVideos = true,
    bool allowDocuments = false,
    bool enableCamera = true,
  }) async {
    if (!enableCamera) return true;

    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) return false;

    final micStatus = await Permission.microphone.status;
    return micStatus.isGranted;
  }
}
