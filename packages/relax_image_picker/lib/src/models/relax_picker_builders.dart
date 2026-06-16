import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';

import 'relax_document_file.dart';

/// Widget-slot builders used by [RelaxPickerTheme].
///
/// Where the theme styles the *default* widgets, these builders let a consumer
/// replace a widget entirely with their own. Any builder left null falls back
/// to the default (themed) widget, so they are fully opt-in.

/// A label-only button (e.g. cancel).
typedef RelaxTextButtonBuilder = Widget Function(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
});

/// A labeled button with a leading icon. [onPressed] is null when disabled.
typedef RelaxIconButtonBuilder = Widget Function(
  BuildContext context, {
  required String label,
  required IconData icon,
  required VoidCallback? onPressed,
});

/// The send/validate button. [onSend] is null when nothing is selected or the
/// picker is busy processing.
typedef RelaxSendButtonBuilder = Widget Function(
  BuildContext context, {
  required int selectedCount,
  required bool processing,
  required VoidCallback? onSend,
});

/// A single view-toggle tab (gallery / documents).
typedef RelaxTabBuilder = Widget Function(
  BuildContext context, {
  required String label,
  required IconData icon,
  required bool selected,
  required VoidCallback onTap,
});

/// A media (photo/video) grid tile.
///
/// [thumbnail] is the ready-made async thumbnail widget — reuse it to avoid
/// re-implementing loading/caching. [selectionIndex] is the 1-based selection
/// order (meaningful only when [selected]).
typedef RelaxMediaTileBuilder = Widget Function(
  BuildContext context, {
  required AssetEntity asset,
  required bool selected,
  required int selectionIndex,
  required bool isVideo,
  required Duration videoDuration,
  required Widget thumbnail,
  required VoidCallback onTap,
  required VoidCallback onLongPress,
});

/// The inline camera tile shown first in the media grid.
typedef RelaxCameraTileBuilder = Widget Function(
  BuildContext context, {
  required VoidCallback onTap,
});

/// A document grid tile. [thumbnail] is the ready-made document thumbnail
/// (image / first PDF page / type icon).
typedef RelaxDocumentTileBuilder = Widget Function(
  BuildContext context, {
  required RelaxDocumentFile document,
  required bool selected,
  required Widget thumbnail,
  required VoidCallback onTap,
});

/// A full-area empty-state placeholder.
typedef RelaxEmptyStateBuilder = Widget Function(BuildContext context);

/// The entire bottom action bar.
typedef RelaxBottomBarBuilder = Widget Function(
  BuildContext context, {
  required int selectedCount,
  required bool canSend,
  required bool processing,
  required bool previewEnabled,
  required VoidCallback onCancel,
  required VoidCallback? onPreview,
  required VoidCallback? onSend,
});

/// A camera capture button. [isVideo] distinguishes the photo vs. video
/// control; [isRecording] is only meaningful when [isVideo].
typedef RelaxCaptureButtonBuilder = Widget Function(
  BuildContext context, {
  required bool isVideo,
  required bool isRecording,
  required VoidCallback onTap,
});
