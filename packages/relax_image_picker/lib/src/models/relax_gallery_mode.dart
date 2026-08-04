/// How the picker lets the user browse their photos/videos.
enum RelaxGalleryMode {
  /// Delegates browsing to the **OS photo picker** (Android Photo Picker /
  /// iOS `PHPickerViewController`). Requires **no** runtime permission and no
  /// `READ_MEDIA_*` manifest declaration, so it is exempt from Google Play's
  /// *Photo and Video Permissions* policy. This is the default.
  systemPicker,

  /// Renders an **in-app gallery grid** (WhatsApp-style) directly inside the
  /// bottom sheet, powered by `photo_manager`.
  ///
  /// This reads the device library, so it **requires** `READ_MEDIA_IMAGES` /
  /// `READ_MEDIA_VIDEO` (Android 13+) and the corresponding iOS photo-library
  /// usage description — and therefore a completed Google Play *Photo and Video
  /// Permissions* declaration. Use it only when browsing the whole library is a
  /// core feature of your app.
  inAppGrid,
}
