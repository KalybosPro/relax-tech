import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Renders a real preview for a document when possible:
///
/// * image files (`jpg`, `png`, …) → the image itself;
/// * `pdf` → a rendered thumbnail of the first page (via `pdfx`);
/// * anything else → an extension-specific icon.
///
/// PDF renders are kept in a small process-wide LRU cache keyed by file path so
/// scrolling the grid doesn't re-render the same pages.
class DocumentThumbnail extends StatefulWidget {
  const DocumentThumbnail({
    super.key,
    required this.path,
    required this.extension,
    this.renderSize = 240,
    this.iconColor,
  });

  final String path;
  final String extension;

  /// Pixel size used when rasterizing the PDF page.
  final double renderSize;

  /// Tint applied to the fallback icon (defaults to `onSurface`).
  final Color? iconColor;

  static const Set<String> imageExtensions = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic',
  };

  @override
  State<DocumentThumbnail> createState() => _DocumentThumbnailState();
}

class _DocumentThumbnailState extends State<DocumentThumbnail> {
  static final Map<String, Uint8List> _pdfCache = {};
  static final List<String> _order = [];
  static const int _maxCache = 120;

  Uint8List? _pdfThumb;
  bool _failed = false;

  bool get _isImage =>
      DocumentThumbnail.imageExtensions.contains(widget.extension.toLowerCase());

  bool get _isPdf => widget.extension.toLowerCase() == 'pdf';

  @override
  void initState() {
    super.initState();
    if (_isPdf) _loadPdf();
  }

  @override
  void didUpdateWidget(covariant DocumentThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _pdfThumb = null;
      _failed = false;
      if (_isPdf) _loadPdf();
    }
  }

  static void _put(String key, Uint8List data) {
    if (!_pdfCache.containsKey(key)) _order.add(key);
    _pdfCache[key] = data;
    while (_order.length > _maxCache) {
      _pdfCache.remove(_order.removeAt(0));
    }
  }

  Future<void> _loadPdf() async {
    final key = widget.path;
    final cached = _pdfCache[key];
    if (cached != null) {
      setState(() => _pdfThumb = cached);
      return;
    }
    if (key.isEmpty || !File(key).existsSync()) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    PdfDocument? doc;
    try {
      doc = await PdfDocument.openFile(key);
      final page = await doc.getPage(1);
      final ratio = page.height == 0 ? 1.0 : page.height / page.width;
      final rendered = await page.render(
        width: widget.renderSize,
        height: widget.renderSize * ratio,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      await page.close();

      if (!mounted) return;
      if (rendered != null) {
        _put(key, rendered.bytes);
        setState(() => _pdfThumb = rendered.bytes);
      } else {
        setState(() => _failed = true);
      }
    } catch (e) {
      debugPrint('PDF thumbnail render failed for $key: $e');
      if (mounted) setState(() => _failed = true);
    } finally {
      await doc?.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isImage && _fileExists) {
      return _Framed(
        child: Image.file(
          File(widget.path),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => _iconFallback(cs),
        ),
      );
    }

    if (_isPdf) {
      if (_pdfThumb != null) {
        return _Framed(
          child: Image.memory(
            _pdfThumb!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );
      }
      if (!_failed) {
        return Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
        );
      }
    }

    return _iconFallback(cs);
  }

  bool get _fileExists => widget.path.isNotEmpty && File(widget.path).existsSync();

  Widget _iconFallback(ColorScheme cs) {
    return Icon(
      _iconData(widget.extension),
      size: 40,
      color: widget.iconColor ?? cs.onSurface,
    );
  }

  IconData _iconData(String ext) {
    switch (ext.toLowerCase()) {
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
      case 'md':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _Framed extends StatelessWidget {
  const _Framed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.expand(child: child),
    );
  }
}
