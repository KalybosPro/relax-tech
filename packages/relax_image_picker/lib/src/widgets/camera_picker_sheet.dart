import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/relax_image_file.dart';
import '../models/relax_picker_theme.dart';
import '../models/relax_video_file.dart';

/// Full-screen camera capture screen.
///
/// Pushed as a route from the gallery sheet (WhatsApp opens the camera full
/// screen rather than as a tab). It pops with the captured [RelaxImageFile] or
/// [RelaxVideoFile], or `null` if the user backs out.
class CameraPickerSheet extends StatefulWidget {
  const CameraPickerSheet({
    super.key,
    this.allowImages = true,
    this.allowVideos = true,
    this.maxSelection = 30,
    this.theme = const RelaxPickerTheme(),
    this.onMediaCaptured,
  });

  final bool allowImages;
  final bool allowVideos;
  final int maxSelection;
  final RelaxPickerTheme theme;

  /// Optional callback, kept for backwards compatibility. The screen always
  /// pops with the captured media as well.
  final void Function(Object media)? onMediaCaptured;

  @override
  State<CameraPickerSheet> createState() => _CameraPickerSheetState();
}

class _CameraPickerSheetState extends State<CameraPickerSheet> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  Timer? _recordTimer;
  Duration _recordElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
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
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: widget.allowVideos,
    );
    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      _controller = controller;
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error setting up camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1 || _isRecording) return;
    setState(() => _isInitialized = false);
    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
    await _controller?.dispose();
    await _setupCamera(_cameras![_cameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    _flashMode =
        _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(_flashMode);
    if (mounted) setState(() {});
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final file = await controller.takePicture();
      final media = RelaxImageFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: file.path,
        mimeType: 'image/jpeg',
        size: await _safeLength(file.path),
        creationDate: DateTime.now(),
      );
      widget.onMediaCaptured?.call(media);
      if (mounted) Navigator.of(context).pop(media);
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }

  Future<void> _toggleRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      if (_isRecording) {
        final file = await controller.stopVideoRecording();
        _recordTimer?.cancel();
        final media = RelaxVideoFile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          path: file.path,
          mimeType: 'video/mp4',
          size: await _safeLength(file.path),
          duration: _recordElapsed,
          creationDate: DateTime.now(),
        );
        widget.onMediaCaptured?.call(media);
        if (mounted) Navigator.of(context).pop(media);
      } else {
        await controller.startVideoRecording();
        _recordElapsed = Duration.zero;
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            setState(
                () => _recordElapsed += const Duration(seconds: 1));
          }
        });
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Error recording video: $e');
    }
  }

  Future<int> _safeLength(String path) async {
    try {
      return await File(path).length();
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Top bar: close + flash.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  if (_isInitialized)
                    IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _flashMode == FlashMode.off
                            ? Icons.flash_off
                            : Icons.flash_on,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Recording indicator.
          if (_isRecording)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fiber_manual_record,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(_recordElapsed),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom controls.
          if (_isInitialized)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: _buildControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton({
    required bool isVideo,
    required bool isRecording,
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
  }) {
    final builder = widget.theme.captureButtonBuilder;
    if (builder != null) {
      return builder(
        context,
        isVideo: isVideo,
        isRecording: isRecording,
        onTap: onTap,
      );
    }
    return _CaptureButton(color: color, icon: icon, onTap: onTap);
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 48),
        if (widget.allowImages && !_isRecording)
          _buildCaptureButton(
            isVideo: false,
            isRecording: false,
            color: Colors.white,
            icon: Icons.camera_alt,
            onTap: _capturePhoto,
          ),
        if (widget.allowVideos)
          _buildCaptureButton(
            isVideo: true,
            isRecording: _isRecording,
            color: _isRecording ? Colors.red : widget.theme.accentColor,
            icon: _isRecording ? Icons.stop : Icons.videocam,
            onTap: _toggleRecording,
          ),
        SizedBox(
          width: 48,
          child: (_cameras != null && _cameras!.length > 1 && !_isRecording)
              ? IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                )
              : null,
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Icon(icon, color: Colors.black, size: 30),
      ),
    );
  }
}
