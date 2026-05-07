import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
      );
      await _controller!.initialize();
    }
  }

  Future<String?> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    final file = await _controller!.takePicture();
    return file.path;
  }

  Future<String?> captureVideo() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    await _controller!.startVideoRecording();
    final file = await _controller!.stopVideoRecording();
    return file.path;
  }
}
