import '../models/quality_models.dart';
import 'dart_parser.dart';

/// Classifies a Dart file into an [ArchLayer] using path heuristics first
/// (fast, high signal) and falling back to inheritance/annotation heuristics.
class LayerClassifier {
  /// Path-segment keywords mapped to layers, checked in priority order.
  static const List<(String, ArchLayer)> _pathHeuristics = [
    ('usecase', ArchLayer.usecase),
    ('use_case', ArchLayer.usecase),
    ('use-case', ArchLayer.usecase),
    ('interactor', ArchLayer.usecase),
    ('datasource', ArchLayer.datasource),
    ('data_source', ArchLayer.datasource),
    ('repositor', ArchLayer.repository), // repository / repositories
    ('controller', ArchLayer.controller),
    ('bloc', ArchLayer.controller),
    ('cubit', ArchLayer.controller),
    ('provider', ArchLayer.controller),
    ('notifier', ArchLayer.controller),
    ('viewmodel', ArchLayer.controller),
    ('view_model', ArchLayer.controller),
    ('api', ArchLayer.apiService),
    ('service', ArchLayer.apiService),
    ('client', ArchLayer.apiService),
    ('model', ArchLayer.model),
    ('entit', ArchLayer.model), // entity / entities
    ('dto', ArchLayer.model),
    ('widget', ArchLayer.widget),
    ('page', ArchLayer.widget),
    ('view', ArchLayer.widget),
    ('screen', ArchLayer.widget),
  ];

  /// Superclass/interface name fragments mapped to layers.
  static const List<(String, ArchLayer)> _typeHeuristics = [
    ('GetxController', ArchLayer.controller),
    ('GetXController', ArchLayer.controller),
    ('Bloc', ArchLayer.controller),
    ('Cubit', ArchLayer.controller),
    ('StateNotifier', ArchLayer.controller),
    ('ChangeNotifier', ArchLayer.controller),
    ('ValueNotifier', ArchLayer.controller),
    ('Notifier', ArchLayer.controller),
    ('Store', ArchLayer.controller), // MobX store
    ('Repository', ArchLayer.repository),
    ('DataSource', ArchLayer.datasource),
    ('Datasource', ArchLayer.datasource),
    ('ApiService', ArchLayer.apiService),
    ('ApiClient', ArchLayer.apiService),
    ('StatelessWidget', ArchLayer.widget),
    ('StatefulWidget', ArchLayer.widget),
    ('State', ArchLayer.widget),
    ('Widget', ArchLayer.widget),
  ];

  ArchLayer classify(String relPath, ParsedFile parsed) {
    final normalized = relPath.replaceAll(r'\', '/').toLowerCase();

    for (final (keyword, layer) in _pathHeuristics) {
      if (_hasSegmentContaining(normalized, keyword)) return layer;
    }

    // Fall back to inheritance/type-name signals across all classes.
    for (final cls in parsed.classes) {
      for (final supertype in cls.supertypes) {
        for (final (fragment, layer) in _typeHeuristics) {
          if (supertype.contains(fragment)) return layer;
        }
      }
      final lowerName = cls.name.toLowerCase();
      for (final (keyword, layer) in _typeHeuristics) {
        if (lowerName.endsWith(keyword.toLowerCase())) return layer;
      }
    }

    // MobX annotation signal.
    for (final cls in parsed.classes) {
      if (cls.annotations.contains('observable') ||
          cls.annotations.contains('action') ||
          cls.mixins.any((m) => m.startsWith(r'_$'))) {
        return ArchLayer.controller;
      }
    }

    return ArchLayer.unknown;
  }

  bool _hasSegmentContaining(String normalizedPath, String keyword) {
    for (final segment in normalizedPath.split('/')) {
      if (segment.contains(keyword)) return true;
    }
    return false;
  }
}
