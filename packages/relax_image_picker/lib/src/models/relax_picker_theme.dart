import 'package:flutter/material.dart';

import 'relax_picker_builders.dart';

/// Centralized styling for the picker UI.
///
/// Every visual aspect — colors, text styles, button styles, icons, shapes and
/// the few previously-hardcoded labels — is overridable here. Pass an instance
/// to `RelaxImagePicker.pick(theme: ...)`.
///
/// All style fields are nullable and fall back to the ambient [ThemeData] (or a
/// sensible default derived from [accentColor]) when left null, so an empty
/// `RelaxPickerTheme()` reproduces the default look.
@immutable
class RelaxPickerTheme {
  const RelaxPickerTheme({
    this.accentColor = const Color(0xFF25D366),

    // Surfaces & shapes
    this.backgroundColor,
    this.sheetBorderRadius = 24,
    this.tileBorderRadius = 12,
    this.heightFactor = 0.92,
    this.dragHandleColor,

    // Text styles
    this.titleTextStyle,
    this.albumTextStyle,
    this.tabTextStyle,
    this.counterTextStyle,
    this.fileNameTextStyle,
    this.fileSizeTextStyle,
    this.durationTextStyle,
    this.selectionBadgeTextStyle,
    this.emptyStateTitleStyle,
    this.emptyStateSubtitleStyle,
    this.previewLabelTextStyle,

    // Buttons
    this.confirmButtonStyle,
    this.cancelButtonStyle,
    this.browseButtonStyle,
    this.sendButtonColor,
    this.sendButtonDisabledColor = Colors.grey,

    // Icons
    this.cameraTileIcon = Icons.photo_camera,
    this.galleryTabIcon = Icons.photo_library_outlined,
    this.documentsTabIcon = Icons.insert_drive_file_outlined,
    this.albumDropdownIcon = Icons.keyboard_arrow_down,
    this.sendIcon = Icons.send_rounded,
    this.previewIcon = Icons.visibility_outlined,
    this.selectedIcon = Icons.check_circle,
    this.unselectedIcon = Icons.radio_button_unchecked,
    this.browseIcon = Icons.add,
    this.emptyMediaIcon = Icons.photo_library_outlined,
    this.emptyDocumentsIcon = Icons.folder_open,
    this.videoBadgeIcon = Icons.videocam,
    this.playIcon = Icons.play_circle_fill,
    this.brokenImageIcon = Icons.broken_image,

    // Labels (newly customizable; French defaults)
    this.noMediaLabel = 'Aucun média',
    this.noDocumentsLabel = 'Aucun document',
    this.noDocumentsHintLabel = 'Touchez « Parcourir » pour en ajouter',
    this.browseLabel = 'Parcourir',
    this.photoLabel = 'Photo',
    this.videoLabel = 'Vidéo',
    this.selectTooltip = 'Sélectionner',
    this.deselectTooltip = 'Désélectionner',
    this.limitedAccessLabel =
        'Vous n\'avez autorisé l\'accès qu\'à certaines photos',
    this.manageAccessLabel = 'Gérer',
    this.maxSelectionLabelBuilder,

    // Widget-slot builders (full overrides; null → default widget)
    this.sendButtonBuilder,
    this.cancelButtonBuilder,
    this.confirmButtonBuilder,
    this.browseButtonBuilder,
    this.tabBuilder,
    this.mediaTileBuilder,
    this.cameraTileBuilder,
    this.documentTileBuilder,
    this.emptyMediaBuilder,
    this.emptyDocumentsBuilder,
    this.bottomBarBuilder,
    this.captureButtonBuilder,
  });

  /// Primary accent used for selection highlights, the send button, etc.
  final Color accentColor;

  // --- Surfaces & shapes ---
  final Color? backgroundColor;
  final double sheetBorderRadius;
  final double tileBorderRadius;

  /// Fraction of the screen height the sheet occupies (0–1).
  final double heightFactor;
  final Color? dragHandleColor;

  // --- Text styles ---
  final TextStyle? titleTextStyle;
  final TextStyle? albumTextStyle;
  final TextStyle? tabTextStyle;
  final TextStyle? counterTextStyle;
  final TextStyle? fileNameTextStyle;
  final TextStyle? fileSizeTextStyle;
  final TextStyle? durationTextStyle;
  final TextStyle? selectionBadgeTextStyle;
  final TextStyle? emptyStateTitleStyle;
  final TextStyle? emptyStateSubtitleStyle;
  final TextStyle? previewLabelTextStyle;

  // --- Buttons ---
  final ButtonStyle? confirmButtonStyle;
  final ButtonStyle? cancelButtonStyle;
  final ButtonStyle? browseButtonStyle;
  final Color? sendButtonColor;
  final Color sendButtonDisabledColor;

  // --- Icons ---
  final IconData cameraTileIcon;
  final IconData galleryTabIcon;
  final IconData documentsTabIcon;
  final IconData albumDropdownIcon;
  final IconData sendIcon;
  final IconData previewIcon;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final IconData browseIcon;
  final IconData emptyMediaIcon;
  final IconData emptyDocumentsIcon;
  final IconData videoBadgeIcon;
  final IconData playIcon;
  final IconData brokenImageIcon;

  // --- Labels ---
  final String noMediaLabel;
  final String noDocumentsLabel;
  final String noDocumentsHintLabel;
  final String browseLabel;
  final String photoLabel;
  final String videoLabel;
  final String selectTooltip;
  final String deselectTooltip;

  /// Shown in the banner when the user granted access to only a subset of their
  /// library (Android 14+ "Selected photos" / iOS limited access).
  final String limitedAccessLabel;

  /// Action label on the limited-access banner that re-opens the system picker
  /// so the user can grant access to more items.
  final String manageAccessLabel;

  /// Builds the "maximum reached" message; defaults to `Maximum <n>`.
  final String Function(int maxSelection)? maxSelectionLabelBuilder;

  // --- Widget-slot builders (full overrides) ---
  final RelaxSendButtonBuilder? sendButtonBuilder;
  final RelaxTextButtonBuilder? cancelButtonBuilder;
  final RelaxIconButtonBuilder? confirmButtonBuilder;
  final RelaxIconButtonBuilder? browseButtonBuilder;
  final RelaxTabBuilder? tabBuilder;
  final RelaxMediaTileBuilder? mediaTileBuilder;
  final RelaxCameraTileBuilder? cameraTileBuilder;
  final RelaxDocumentTileBuilder? documentTileBuilder;
  final RelaxEmptyStateBuilder? emptyMediaBuilder;
  final RelaxEmptyStateBuilder? emptyDocumentsBuilder;
  final RelaxBottomBarBuilder? bottomBarBuilder;
  final RelaxCaptureButtonBuilder? captureButtonBuilder;

  /// Resolved color used for the send button background.
  Color get resolvedSendButtonColor => sendButtonColor ?? accentColor;

  String maxSelectionLabel(int maxSelection) =>
      maxSelectionLabelBuilder?.call(maxSelection) ?? 'Maximum $maxSelection';

  RelaxPickerTheme copyWith({
    Color? accentColor,
    Color? backgroundColor,
    double? sheetBorderRadius,
    double? tileBorderRadius,
    double? heightFactor,
    Color? dragHandleColor,
    TextStyle? titleTextStyle,
    TextStyle? albumTextStyle,
    TextStyle? tabTextStyle,
    TextStyle? counterTextStyle,
    TextStyle? fileNameTextStyle,
    TextStyle? fileSizeTextStyle,
    TextStyle? durationTextStyle,
    TextStyle? selectionBadgeTextStyle,
    TextStyle? emptyStateTitleStyle,
    TextStyle? emptyStateSubtitleStyle,
    TextStyle? previewLabelTextStyle,
    ButtonStyle? confirmButtonStyle,
    ButtonStyle? cancelButtonStyle,
    ButtonStyle? browseButtonStyle,
    Color? sendButtonColor,
    Color? sendButtonDisabledColor,
    IconData? cameraTileIcon,
    IconData? galleryTabIcon,
    IconData? documentsTabIcon,
    IconData? albumDropdownIcon,
    IconData? sendIcon,
    IconData? previewIcon,
    IconData? selectedIcon,
    IconData? unselectedIcon,
    IconData? browseIcon,
    IconData? emptyMediaIcon,
    IconData? emptyDocumentsIcon,
    IconData? videoBadgeIcon,
    IconData? playIcon,
    IconData? brokenImageIcon,
    String? noMediaLabel,
    String? noDocumentsLabel,
    String? noDocumentsHintLabel,
    String? browseLabel,
    String? photoLabel,
    String? videoLabel,
    String? selectTooltip,
    String? deselectTooltip,
    String? limitedAccessLabel,
    String? manageAccessLabel,
    String Function(int maxSelection)? maxSelectionLabelBuilder,
    RelaxSendButtonBuilder? sendButtonBuilder,
    RelaxTextButtonBuilder? cancelButtonBuilder,
    RelaxIconButtonBuilder? confirmButtonBuilder,
    RelaxIconButtonBuilder? browseButtonBuilder,
    RelaxTabBuilder? tabBuilder,
    RelaxMediaTileBuilder? mediaTileBuilder,
    RelaxCameraTileBuilder? cameraTileBuilder,
    RelaxDocumentTileBuilder? documentTileBuilder,
    RelaxEmptyStateBuilder? emptyMediaBuilder,
    RelaxEmptyStateBuilder? emptyDocumentsBuilder,
    RelaxBottomBarBuilder? bottomBarBuilder,
    RelaxCaptureButtonBuilder? captureButtonBuilder,
  }) {
    return RelaxPickerTheme(
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      sheetBorderRadius: sheetBorderRadius ?? this.sheetBorderRadius,
      tileBorderRadius: tileBorderRadius ?? this.tileBorderRadius,
      heightFactor: heightFactor ?? this.heightFactor,
      dragHandleColor: dragHandleColor ?? this.dragHandleColor,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      albumTextStyle: albumTextStyle ?? this.albumTextStyle,
      tabTextStyle: tabTextStyle ?? this.tabTextStyle,
      counterTextStyle: counterTextStyle ?? this.counterTextStyle,
      fileNameTextStyle: fileNameTextStyle ?? this.fileNameTextStyle,
      fileSizeTextStyle: fileSizeTextStyle ?? this.fileSizeTextStyle,
      durationTextStyle: durationTextStyle ?? this.durationTextStyle,
      selectionBadgeTextStyle:
          selectionBadgeTextStyle ?? this.selectionBadgeTextStyle,
      emptyStateTitleStyle: emptyStateTitleStyle ?? this.emptyStateTitleStyle,
      emptyStateSubtitleStyle:
          emptyStateSubtitleStyle ?? this.emptyStateSubtitleStyle,
      previewLabelTextStyle:
          previewLabelTextStyle ?? this.previewLabelTextStyle,
      confirmButtonStyle: confirmButtonStyle ?? this.confirmButtonStyle,
      cancelButtonStyle: cancelButtonStyle ?? this.cancelButtonStyle,
      browseButtonStyle: browseButtonStyle ?? this.browseButtonStyle,
      sendButtonColor: sendButtonColor ?? this.sendButtonColor,
      sendButtonDisabledColor:
          sendButtonDisabledColor ?? this.sendButtonDisabledColor,
      cameraTileIcon: cameraTileIcon ?? this.cameraTileIcon,
      galleryTabIcon: galleryTabIcon ?? this.galleryTabIcon,
      documentsTabIcon: documentsTabIcon ?? this.documentsTabIcon,
      albumDropdownIcon: albumDropdownIcon ?? this.albumDropdownIcon,
      sendIcon: sendIcon ?? this.sendIcon,
      previewIcon: previewIcon ?? this.previewIcon,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      unselectedIcon: unselectedIcon ?? this.unselectedIcon,
      browseIcon: browseIcon ?? this.browseIcon,
      emptyMediaIcon: emptyMediaIcon ?? this.emptyMediaIcon,
      emptyDocumentsIcon: emptyDocumentsIcon ?? this.emptyDocumentsIcon,
      videoBadgeIcon: videoBadgeIcon ?? this.videoBadgeIcon,
      playIcon: playIcon ?? this.playIcon,
      brokenImageIcon: brokenImageIcon ?? this.brokenImageIcon,
      noMediaLabel: noMediaLabel ?? this.noMediaLabel,
      noDocumentsLabel: noDocumentsLabel ?? this.noDocumentsLabel,
      noDocumentsHintLabel: noDocumentsHintLabel ?? this.noDocumentsHintLabel,
      browseLabel: browseLabel ?? this.browseLabel,
      photoLabel: photoLabel ?? this.photoLabel,
      videoLabel: videoLabel ?? this.videoLabel,
      selectTooltip: selectTooltip ?? this.selectTooltip,
      deselectTooltip: deselectTooltip ?? this.deselectTooltip,
      limitedAccessLabel: limitedAccessLabel ?? this.limitedAccessLabel,
      manageAccessLabel: manageAccessLabel ?? this.manageAccessLabel,
      maxSelectionLabelBuilder:
          maxSelectionLabelBuilder ?? this.maxSelectionLabelBuilder,
      sendButtonBuilder: sendButtonBuilder ?? this.sendButtonBuilder,
      cancelButtonBuilder: cancelButtonBuilder ?? this.cancelButtonBuilder,
      confirmButtonBuilder: confirmButtonBuilder ?? this.confirmButtonBuilder,
      browseButtonBuilder: browseButtonBuilder ?? this.browseButtonBuilder,
      tabBuilder: tabBuilder ?? this.tabBuilder,
      mediaTileBuilder: mediaTileBuilder ?? this.mediaTileBuilder,
      cameraTileBuilder: cameraTileBuilder ?? this.cameraTileBuilder,
      documentTileBuilder: documentTileBuilder ?? this.documentTileBuilder,
      emptyMediaBuilder: emptyMediaBuilder ?? this.emptyMediaBuilder,
      emptyDocumentsBuilder:
          emptyDocumentsBuilder ?? this.emptyDocumentsBuilder,
      bottomBarBuilder: bottomBarBuilder ?? this.bottomBarBuilder,
      captureButtonBuilder: captureButtonBuilder ?? this.captureButtonBuilder,
    );
  }
}
