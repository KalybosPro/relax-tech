import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Import for openAppSettings

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
  List<RelaxDocumentFile> _allDocuments = [];
  final List<RelaxDocumentFile> _selectedDocuments = [];
  bool _isLoading = false;
  bool _hasStoragePermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    PermissionStatus status = await Permission.storage.status;
    if (status.isDenied) {
      status = await Permission.storage.request();
    }

    if (mounted) {
      setState(() {
        _hasStoragePermission = status.isGranted;
      });
      if (_hasStoragePermission) {
        _loadDocuments();
      }
    }
  }

  Future<void> _loadDocuments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final List<RelaxDocumentFile> docs = [];
      final List<Directory> dirsToScan = [];

      dirsToScan.add(await getApplicationDocumentsDirectory());

      if (Platform.isAndroid) {
        dirsToScan.add(Directory('/storage/emulated/0/Download'));
        dirsToScan.add(Directory('/storage/emulated/0/Documents'));
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.documents);
        if (extDirs != null) dirsToScan.addAll(extDirs);
        final extDirs2 = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDirs2 != null) dirsToScan.addAll(extDirs2);
      }

      for (final dir in dirsToScan) {
        if (await dir.exists()) {
          try {
            final entities = await dir.list().toList();
            for (final entity in entities) {
              if (entity is File) {
                final ext = entity.path.split('.').last.toLowerCase();
                if (_isSupportedExtension(ext)) {
                  final stat = await entity.stat();
                  docs.add(_mapToFile(entity, stat, ext));
                }
              }
            }
          } catch (e) {
            debugPrint('Error listing directory ${dir.path}: $e');
          }
        }
      }

      final uniqueDocs = {for (var d in docs) d.path: d}.values.toList();
      uniqueDocs.sort((a, b) => (b.creationDate ?? DateTime(0)).compareTo(a.creationDate ?? DateTime(0)));

      if (mounted) {
        setState(() => _allDocuments = uniqueDocs);
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDocuments() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'zip', 'rar'],
      );

      if (result != null) {
        final documents = result.files.map(_mapFilePickerFile).toList();

        setState(() {
          for (final doc in documents) {
            // Ajouter aux documents récents s'il n'y est pas déjà
            if (!_allDocuments.any((d) => d.path == doc.path)) {
              _allDocuments.insert(0, doc);
            }
            // Ajouter à la sélection si possible
            if (!_selectedDocuments.any((d) => d.path == doc.path)) {
              if (_selectedDocuments.length < widget.maxSelection) {
                _selectedDocuments.add(doc);
              }
            }
          }
        });

        widget.onDocumentsSelected(_selectedDocuments);
      }
    } catch (e) {
      debugPrint('Error picking documents: $e');
    }
  }

  bool _isSupportedExtension(String ext) {
    return {
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'zip', 'rar'
    }.contains(ext.toLowerCase());
  }

  RelaxDocumentFile _mapToFile(File file, FileStat stat, String ext) {
    return RelaxDocumentFile(
      id: file.path,
      path: file.path,
      mimeType: _getMimeType(ext),
      size: stat.size,
      fileName: file.path.split(Platform.pathSeparator).last,
      extension: ext,
      canPreview: _canPreview(ext),
      creationDate: stat.modified,
    );
  }

  RelaxDocumentFile _mapFilePickerFile(PlatformFile file) {
    return RelaxDocumentFile(
      id: file.path ?? file.identifier ?? file.name,
      path: file.path ?? '',
      mimeType: _getMimeType(file.extension),
      size: file.size,
      fileName: file.name,
      extension: file.extension ?? '',
      canPreview: _canPreview(file.extension),
      creationDate: DateTime.now(),
    );
  }

  bool _canPreview(String? extension) {
    final previewable = <String>{'pdf', 'txt', 'md', 'jpg', 'jpeg', 'png'};
    return extension != null && previewable.contains(extension.toLowerCase());
  }

  void _toggleDocument(RelaxDocumentFile doc) {
    setState(() {
      final index = _selectedDocuments.indexWhere((d) => d.path == doc.path);
      if (index >= 0) {
        _selectedDocuments.removeAt(index);
      } else if (_selectedDocuments.length < widget.maxSelection) {
        _selectedDocuments.add(doc);
      }
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

  Widget _buildPermissionDeniedMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Permission d\'accès aux documents refusée.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Veuillez accorder la permission de stockage dans les paramètres de l\'application.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDocumentsFoundMessage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.file_copy, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Aucun document trouvé', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Documents récents',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton.icon(
                onPressed: _pickDocuments,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Parcourir'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : !_hasStoragePermission
                  ? _buildPermissionDeniedMessage()
                  : _allDocuments.isEmpty
                      ? _buildNoDocumentsFoundMessage()
                      : _buildDocumentsGridView(),
        ),
      ],
    );
  }

  Widget _buildDocumentsGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: _allDocuments.length,
      itemBuilder: (context, index) {
        final doc = _allDocuments[index];
        final isSelected = _selectedDocuments.any((d) => d.path == doc.path);
        return InkWell(
          onTap: () => _toggleDocument(doc),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected ? Colors.blue.withValues(alpha: 0.05) : Colors.white,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getFileIcon(doc.extension),
                        size: 40,
                        color: isSelected ? Colors.blueAccent : Colors.blueGrey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        doc.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFileSize(doc.size),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.check_circle, color: Colors.blueAccent, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
