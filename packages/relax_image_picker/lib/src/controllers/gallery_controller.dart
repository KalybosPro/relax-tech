/// Controller for gallery workflows.
///
/// Gallery browsing is delegated to the OS photo picker (see
/// `GalleryPickerSheet`), which returns files directly — there is no in-app
/// library index or pagination to manage.
class GalleryController {
  /// Prepares any gallery-related state.
  Future<void> initialize() async {}

  /// Launches the OS photo picker and appends the selection.
  Future<void> addFromGallery() async {}

  void toggleSelection(String id) {
    // Select or deselect a picked item and update counters.
  }
}
