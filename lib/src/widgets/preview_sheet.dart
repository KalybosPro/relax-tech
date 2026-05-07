import 'dart:io';
import 'package:flutter/material.dart';
import '../models/relax_media_file.dart';
import '../models/relax_image_file.dart';
import '../models/relax_video_file.dart';
import '../models/relax_document_file.dart';

class PreviewSheet extends StatefulWidget {
  final List<RelaxMediaFile> selectedFiles;
  final Function(List<RelaxMediaFile>)? onSelectionChanged;
  final VoidCallback? onConfirm;

  const PreviewSheet({
    super.key,
    required this.selectedFiles,
    this.onSelectionChanged,
    this.onConfirm,
  });

  @override
  State<PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends State<PreviewSheet> {
  late List<RelaxMediaFile> _files;

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.selectedFiles);
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
    widget.onSelectionChanged?.call(_files);
  }

  Widget _buildFilePreview(RelaxMediaFile file, int index) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildFileContent(file),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeFile(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        if (file is RelaxVideoFile)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDuration(file.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFileContent(RelaxMediaFile file) {
    if (file is RelaxImageFile) {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 120,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else if (file is RelaxVideoFile) {
      return Container(
        width: double.infinity,
        height: 120,
        color: Colors.grey.shade200,
        child: const Icon(Icons.video_file, color: Colors.grey),
      );
    } else if (file is RelaxDocumentFile) {
      return Container(
        width: double.infinity,
        height: 120,
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, color: Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              file.path.split('/').last,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      height: 120,
      color: Colors.grey.shade200,
      child: const Icon(Icons.file_present, color: Colors.grey),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aperçu de la sélection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_files.length} élément(s)',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _files.isEmpty
                ? const Center(
                    child: Text('Aucun élément sélectionné'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      return _buildFilePreview(_files[index], index);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _files.isEmpty
                        ? null
                        : () {
                            widget.onConfirm?.call();
                            Navigator.of(context).pop(_files);
                          },
                    child: const Text('Confirmer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
