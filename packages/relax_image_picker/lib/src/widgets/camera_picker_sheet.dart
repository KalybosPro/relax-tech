import 'package:flutter/material.dart';

import '../models/relax_media_file.dart';
import '../models/relax_picker_theme.dart';
import 'camera_capture_view.dart';

/// Full-screen camera capture screen.
///
/// Pushed as a route from the gallery sheet (WhatsApp opens the camera full
/// screen rather than as a tab). It pops with the captured `RelaxImageFile` or
/// `RelaxVideoFile`, or `null` if the user backs out.
class CameraPickerSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CameraCaptureView(
        allowImages: allowImages,
        allowVideos: allowVideos,
        theme: theme,
        onClose: () => Navigator.of(context).pop(),
        onCaptured: (RelaxMediaFile media) {
          onMediaCaptured?.call(media);
          Navigator.of(context).pop(media);
        },
      ),
    );
  }
}
