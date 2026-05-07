import 'package:file_picker/file_picker.dart';

import '../models/relax_document_file.dart';

class DocumentService {
  Future<List<RelaxDocumentFile>> pickDocuments({
    List<String>? acceptedTypes,
    int maxSelection = 30,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: acceptedTypes == null ? FileType.any : FileType.custom,
      allowedExtensions: acceptedTypes,
    );

    if (result == null) {
      return [];
    }

    return result.files.map((file) {
      return RelaxDocumentFile(
        id: file.identifier ?? file.name,
        path: file.path ?? '',
        mimeType: _getMimeType(file.extension),
        size: file.size,
        fileName: file.name,
        extension: file.extension ?? '',
        canPreview: _canPreview(file.extension),
        creationDate: DateTime.now(),
      );
    }).toList();
  }

  bool _canPreview(String? extension) {
    final previewable = <String>{'pdf', 'txt', 'md', 'jpg', 'jpeg', 'png'};
    return extension != null && previewable.contains(extension.toLowerCase());
  }

  String _getMimeType(String? extension) {
    if (extension == null) return 'application/octet-stream';
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      default:
        return 'application/octet-stream';
    }
  }
}
