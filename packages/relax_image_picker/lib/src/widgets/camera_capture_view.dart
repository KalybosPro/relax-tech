import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/relax_image_file.dart';
import '../models/relax_media_file.dart';
import '../models/relax_picker_theme.dart';
import '../models/relax_video_file.dart';

/// Live camera preview plus its capture controls, without any surrounding
/// chrome.
///
/// Shared by the two ways the package surfaces the camera:
/// * [CameraPickerSheet] — full-screen route that pops with the capture.
/// * the camera-first picker (`cameraFirst: true`) — the preview stays behind a
///   draggable gallery panel and every capture is appended to the selection.
class CameraCaptureView extends StatefulWidget {
  const CameraCaptureView({
    super.key,
    required this.onCaptured,
    this.allowImages = true,
    this.allowVideos = true,
    this.theme = const RelaxPickerTheme(),
    this.bottomInset = 0,
    this.onClose,
  });

  final bool allowImages;
  final bool allowVideos;
  final RelaxPickerTheme theme;

  /// Called with a [RelaxImageFile] / [RelaxVideoFile] each time the user
  /// captures something.
  final ValueChanged<RelaxMediaFile> onCaptured;

  /// Space reserved at the bottom (the camera-first thumbnail strip) so the
  /// capture controls stay clear of it.
  final double bottomInset;

  /// When non-null, a close button is rendered in the top bar.
  final VoidCallback? onClose;

  @override
  State<CameraCaptureView> createState() => _CameraCaptureViewState();
}

class _CameraCaptureViewState extends State<CameraCaptureView> {
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
    _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(_flashMode);
    if (mounted) setState(() {});
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final file = await controller.takePicture();
      widget.onCaptured(
        RelaxImageFile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          path: file.path,
          mimeType: 'image/jpeg',
          size: await _safeLength(file.path),
          creationDate: DateTime.now(),
        ),
      );
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
        final elapsed = _recordElapsed;
        if (mounted) setState(() => _isRecording = false);
        widget.onCaptured(
          RelaxVideoFile(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            path: file.path,
            mimeType: 'video/mp4',
            size: await _safeLength(file.path),
            duration: elapsed,
            creationDate: DateTime.now(),
          ),
        );
      } else {
        await controller.startVideoRecording();
        _recordElapsed = Duration.zero;
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            setState(() => _recordElapsed += const Duration(seconds: 1));
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
    return Stack(
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
                if (widget.onClose != null)
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  )
                else
                  const SizedBox(width: 48),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      color: Colors.white,
                      size: 14,
                    ),
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
            bottom: widget.bottomInset + 32,
            left: 0,
            right: 0,
            child: _buildControls(),
          ),
      ],
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
