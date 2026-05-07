import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/relax_document_file.dart';

class DocumentPickerSheet extends StatefulWidget {
  final int maxSelection;
  final Function(List<RelaxDocumentFile>) onDocumentsSelected;

  const DocumentPickerSheet({
    super.key,
    this.maxSelection = 30,
    required this.onDocumentsSelected,
  });

  @override
  State<DocumentPickerSheet> createState() => _DocumentPickerSheetState();
}

class _DocumentPickerSheetState extends State<DocumentPickerSheet> {
  List<RelaxDocumentFile> _selectedDocuments = [];
  bool _isLoading = false;

  Future<void> _pickDocuments() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        final documents = result.files.map((file) {
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

        setState(() {
          _selectedDocuments.addAll(documents);
          if (_selectedDocuments.length > widget.maxSelection) {
            _selectedDocuments = _selectedDocuments.sublist(0, widget.maxSelection);
          }
        });

        widget.onDocumentsSelected(_selectedDocuments);
      }
    } catch (e) {
      debugPrint('Error picking documents: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _canPreview(String? extension) {
    final previewable = <String>{'pdf', 'txt', 'md', 'jpg', 'jpeg', 'png'};
    return extension != null && previewable.contains(extension.toLowerCase());
  }

  void _removeDocument(int index) {
    setState(() {
      _selectedDocuments.removeAt(index);
    });
    widget.onDocumentsSelected(_selectedDocuments);
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

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickDocuments,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_open),
            label: Text(_isLoading ? 'Chargement...' : 'Sélectionner des documents'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: _selectedDocuments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.file_copy, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun document sélectionné',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _selectedDocuments.length,
                  itemBuilder: (context, index) {
                    final doc = _selectedDocuments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          _getFileIcon(doc.extension),
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(
                        doc.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${doc.extension.toUpperCase()} • ${_formatFileSize(doc.size)}',
                      ),
                      trailing: IconButton(
                        onPressed: () => _removeDocument(index),
                        icon: const Icon(Icons.close),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
