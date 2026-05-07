import 'package:flutter/widgets.dart';

/// Controller for document selection flows.
class DocumentController {
  Future<void> initialize() async {
    // Prepare document picker defaults if needed.
  }

  Future<List<String>> pickDocuments({
    required BuildContext context,
    List<String>? acceptedTypes,
    int maxSelection = 30,
  }) async {
    // Pick files via file_picker and return selected paths.
    return <String>[];
  }
}
