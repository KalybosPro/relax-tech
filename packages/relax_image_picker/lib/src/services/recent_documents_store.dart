import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/relax_document_file.dart';

/// Persisted snapshot returned by [RecentDocumentsStore.load].
class RecentDocumentsData {
  const RecentDocumentsData({required this.documents});

  /// Recently picked documents, newest first.
  final List<RelaxDocumentFile> documents;

  static const RecentDocumentsData empty = RecentDocumentsData(documents: []);
}

/// Caches the document picker state between sessions so the grid can be
/// pre-populated instead of forcing the user to browse from scratch.
///
/// Stored as a small JSON file in the application support directory. Only
/// metadata (path, name, size, extension) is persisted — never file contents.
class RecentDocumentsStore {
  static const String _fileName = 'relax_recent_documents.json';

  /// Hard cap so the cache can't grow unbounded.
  static const int maxEntries = 60;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<RecentDocumentsData> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return RecentDocumentsData.empty;

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return RecentDocumentsData.empty;

      final rawDocs = decoded['documents'];
      final documents = <RelaxDocumentFile>[];
      if (rawDocs is List) {
        for (final entry in rawDocs) {
          if (entry is Map<String, dynamic>) {
            try {
              documents.add(RelaxDocumentFile.fromJson(entry));
            } catch (_) {
              // Skip malformed entries rather than failing the whole load.
            }
          }
        }
      }

      return RecentDocumentsData(documents: documents);
    } catch (e) {
      debugPrint('RecentDocumentsStore.load failed: $e');
      return RecentDocumentsData.empty;
    }
  }

  Future<void> save({required List<RelaxDocumentFile> documents}) async {
    try {
      final file = await _file();
      final trimmed = documents.take(maxEntries).toList();
      await file.writeAsString(
        jsonEncode({
          'documents': trimmed.map((d) => d.toJson()).toList(),
        }),
      );
    } catch (e) {
      debugPrint('RecentDocumentsStore.save failed: $e');
    }
  }
}
