import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/relax_document_file.dart';
import '../models/relax_picker_theme.dart';
import '../services/recent_documents_store.dart';
import 'document_thumbnail.dart';

/// Document picker view.
///
/// Relies on the platform document provider (Storage Access Framework on
/// Android) through `file_picker`, so it needs no legacy storage permission and
/// works on Android 13+.
///
/// Unlike a one-shot file dialog, this view keeps a *pre-populated* grid:
/// recently picked documents are cached between sessions
/// (see [RecentDocumentsStore]) and shown on open.
///
/// Selection is *controlled*: the owning sheet holds the source of truth and
/// passes it down via [selectedPaths], reacting to [onToggle]. This keeps the
/// selection consistent across tab switches and with the shared preview.
class DocumentPickerSheet extends StatefulWidget {
  const DocumentPickerSheet({
    super.key,
    this.maxSelection = 30,
    required this.theme,
    this.acceptedExtensions,
    required this.selectedPaths,
    required this.onToggle,
  });

  final int maxSelection;
  final RelaxPickerTheme theme;
  final List<String>? acceptedExtensions;

  /// Paths of documents currently selected (owned by the parent).
  final Set<String> selectedPaths;

  /// Called when the user taps a document tile (or a freshly browsed file is
  /// auto-selected). The parent decides whether to add or remove it.
  final ValueChanged<RelaxDocumentFile> onToggle;

  @override
  State<DocumentPickerSheet> createState() => _DocumentPickerSheetState();
}

class _DocumentPickerSheetState extends State<DocumentPickerSheet> {
  static const List<String> _defaultExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'zip', 'rar',
  ];

  final RecentDocumentsStore _store = RecentDocumentsStore();

  final List<RelaxDocumentFile> _documents = [];

  bool _initializing = true;
  bool _isLoading = false;

  List<String> get _acceptedExtensions =>
      widget.acceptedExtensions ?? _defaultExtensions;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _restore() async {
    final data = await _store.load();
    if (!mounted) return;

    // Drop cached entries whose underlying file no longer exists.
    final stillThere = data.documents
        .where((d) => d.path.isNotEmpty && File(d.path).existsSync())
        .toList();

    setState(() {
      _documents
        ..clear()
        ..addAll(stillThere);
      _initializing = false;
    });

    _persist();
  }

  void _persist() {
    _store.save(documents: _documents);
  }

  // ---------------------------------------------------------------------------
  // Picking
  // ---------------------------------------------------------------------------

  Future<void> _pickDocuments() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _acceptedExtensions,
      );

      if (result != null) {
        final picked = result.files.map(_mapPlatformFile).toList();
        setState(() {
          for (final doc in picked) {
            _addDocument(doc);
          }
        });
        _persist();

        // Auto-select files the user explicitly picked (deduped by path).
        final seen = <String>{};
        for (final doc in picked) {
          if (!widget.selectedPaths.contains(doc.path) && seen.add(doc.path)) {
            widget.onToggle(doc);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking documents: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Adds [doc] to the grid if not already present. Returns whether it was new.
  bool _addDocument(RelaxDocumentFile doc) {
    if (_documents.any((d) => d.path == doc.path)) return false;
    _documents.insert(0, doc);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  RelaxDocumentFile _mapPlatformFile(PlatformFile file) {
    final ext = file.extension ?? '';
    return RelaxDocumentFile(
      id: file.path ?? file.identifier ?? file.name,
      path: file.path ?? '',
      mimeType: _mimeType(ext),
      size: file.size,
      fileName: file.name,
      extension: ext,
      canPreview: _canPreview(ext),
      creationDate: DateTime.now(),
    );
  }

  bool _canPreview(String ext) =>
      const {'pdf', 'txt', 'md', 'jpg', 'jpeg', 'png'}.contains(ext.toLowerCase());

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
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

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: _initializing || _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: widget.theme.accentColor))
              : _documents.isEmpty
                  ? _buildEmptyState(cs)
                  : _buildGrid(cs),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: widget.theme.browseButtonBuilder?.call(
                context,
                label: widget.theme.browseLabel,
                icon: widget.theme.browseIcon,
                onPressed: _isLoading ? null : _pickDocuments,
              ) ??
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickDocuments,
                  style: widget.theme.browseButtonStyle ??
                      OutlinedButton.styleFrom(
                        foregroundColor: widget.theme.accentColor,
                        side: BorderSide(color: widget.theme.accentColor),
                      ),
                  icon: Icon(widget.theme.browseIcon),
                  label: Text(widget.theme.browseLabel),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    final builder = widget.theme.emptyDocumentsBuilder;
    if (builder != null) return builder(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.theme.emptyDocumentsIcon,
              size: 64, color: cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            widget.theme.noDocumentsLabel,
            style: widget.theme.emptyStateTitleStyle ??
                TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 4),
          Text(
            widget.theme.noDocumentsHintLabel,
            textAlign: TextAlign.center,
            style: widget.theme.emptyStateSubtitleStyle ??
                TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(ColorScheme cs) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];
        final selected = widget.selectedPaths.contains(doc.path);
        final thumbnail = DocumentThumbnail(
          key: ValueKey(doc.path),
          path: doc.path,
          extension: doc.extension,
          iconColor: selected ? widget.theme.accentColor : cs.onSurface,
        );

        if (widget.theme.documentTileBuilder != null) {
          return widget.theme.documentTileBuilder!(
            context,
            document: doc,
            selected: selected,
            thumbnail: thumbnail,
            onTap: () => widget.onToggle(doc),
          );
        }

        return InkWell(
          onTap: () => widget.onToggle(doc),
          borderRadius: BorderRadius.circular(widget.theme.tileBorderRadius),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.theme.tileBorderRadius),
              border: Border.all(
                color: selected
                    ? widget.theme.accentColor
                    : cs.onSurface.withValues(alpha: 0.12),
                width: selected ? 2 : 1,
              ),
              color: selected
                  ? widget.theme.accentColor.withValues(alpha: 0.06)
                  : Colors.transparent,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Center(child: thumbnail),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      doc.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: (widget.theme.fileNameTextStyle ??
                              const TextStyle(fontSize: 11))
                          .copyWith(
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatSize(doc.size),
                      style: widget.theme.fileSizeTextStyle ??
                          TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
                if (selected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(widget.theme.selectedIcon,
                        color: widget.theme.accentColor, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
