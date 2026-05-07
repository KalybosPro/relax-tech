import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/relax_image_file.dart';
import '../models/relax_video_file.dart';

class CameraPickerSheet extends StatefulWidget {
  final bool allowImages;
  final bool allowVideos;
  final int maxSelection;
  final Function(dynamic) onMediaCaptured;

  const CameraPickerSheet({
    super.key,
    this.allowImages = true,
    this.allowVideos = true,
    this.maxSelection = 30,
    required this.onMediaCaptured,
  });

  @override
  State<CameraPickerSheet> createState() => _CameraPickerSheetState();
}

class _CameraPickerSheetState extends State<CameraPickerSheet> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isInitialized = false;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _setupCamera(_cameras![_cameraIndex]);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: widget.allowVideos,
    );

    try {
      await _controller!.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error setting up camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;

    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
    await _controller?.dispose();
    await _setupCamera(_cameras![_cameraIndex]);
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final file = await _controller!.takePicture();
      final imageFile = RelaxImageFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: file.path,
        mimeType: 'image/jpeg',
        size: 0, // Size will be determined later if needed
        width: 0, // Would need to get from image metadata
        height: 0,
        creationDate: DateTime.now(),
      );
      widget.onMediaCaptured(imageFile);
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }

  Future<void> _startStopRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_isRecording) {
        final file = await _controller!.stopVideoRecording();
        setState(() => _isRecording = false);

        final videoFile = RelaxVideoFile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          path: file.path,
          mimeType: 'video/mp4',
          size: 0, // Size will be determined later if needed
          duration: Duration.zero, // Would need to get from video metadata
          width: 0,
          height: 0,
          creationDate: DateTime.now(),
        );
        widget.onMediaCaptured(videoFile);
      } else {
        await _controller!.startVideoRecording();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Error recording video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black45,
            ),
          ),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.allowImages)
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: _capturePhoto,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.camera, color: Colors.black, size: 32),
                  ),
                ),
              if (widget.allowVideos)
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: _startStopRecording,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                      backgroundColor: _isRecording ? Colors.red : Colors.white,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.videocam,
                      color: _isRecording ? Colors.white : Colors.black,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_isRecording)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'REC',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
