import '../models/quality_models.dart';
import 'file_analyzer.dart';

/// Builds a [DependencyGraph] from analyzed files.
///
/// A node is created per (file, class). Edges are added heuristically from the
/// syntactic call/receiver information: a `calls`/`injects` edge links a class
/// to another class whose type name matches a call receiver or a constructor
/// field type. This is intentionally approximate (unresolved AST) but enough
/// to visualize the UI → Controller → UseCase → Repository → … → API flow.
class DependencyGraphBuilder {
  DependencyGraph build(List<AnalyzedFile> files) {
    final nodes = <String, GraphNode>{};

    // Index class name → node id for edge resolution.
    final classToNode = <String, String>{};

    for (final file in files) {
      if (file.info.isTest) continue;
      for (final cls in file.parsed.classes) {
        final id = '${file.relPath}::${cls.name}';
        nodes[id] = GraphNode(
          id: id,
          layer: file.info.layer,
          filePath: file.relPath,
          label: cls.name,
        );
        classToNode.putIfAbsent(cls.name, () => id);
      }
    }

    final edges = <GraphEdge>[];
    final seen = <String>{};

    void addEdge(String from, String to, String kind) {
      if (from == to) return;
      final key = '$from|$to|$kind';
      if (seen.add(key)) {
        edges.add(GraphEdge(from: from, to: to, kind: kind));
      }
    }

    for (final file in files) {
      if (file.info.isTest) continue;
      for (final cls in file.parsed.classes) {
        final fromId = '${file.relPath}::${cls.name}';

        // Injection edges: constructor/field types that resolve to a node.
        for (final supertype in cls.supertypes) {
          final target = classToNode[_baseTypeName(supertype)];
          if (target != null) addEdge(fromId, target, 'injects');
        }

        // Call edges: receivers whose type matches a known class.
        for (final method in cls.methods) {
          for (final call in method.calls) {
            final receiver = call.receiver;
            if (receiver == null) continue;
            final target = _resolveReceiver(receiver, classToNode);
            if (target != null) addEdge(fromId, target, 'calls');
          }
        }
      }
    }

    return DependencyGraph(nodes: nodes, edges: edges);
  }

  /// Strips generic arguments: `Bloc<E, S>` → `Bloc`.
  String _baseTypeName(String type) {
    final idx = type.indexOf('<');
    return idx == -1 ? type : type.substring(0, idx);
  }

  /// Maps a receiver expression (e.g. `_authRepository`, `AuthRepository`) to a
  /// class node by fuzzy-matching the stripped identifier against class names.
  String? _resolveReceiver(String receiver, Map<String, String> classToNode) {
    final cleaned = receiver.replaceAll('_', '').replaceAll('this.', '');
    for (final entry in classToNode.entries) {
      final className = entry.key;
      if (cleaned.toLowerCase() == className.toLowerCase()) return entry.value;
      // Field named after its type, e.g. `authRepository` → `AuthRepository`.
      if (cleaned.toLowerCase() == _lowerFirst(className).toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

  String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
}
