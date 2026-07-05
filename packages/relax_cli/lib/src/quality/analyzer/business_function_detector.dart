import '../config/quality_config.dart';
import '../models/quality_models.dart';
import 'dart_parser.dart';

/// Detects "business functions" — methods that carry domain logic (login,
/// createOrder, fetchProducts, …). A method qualifies when its name matches a
/// business verb from the configured dictionary AND it looks like business
/// logic (async, returns a Future, or calls into a repository/api/datasource).
class BusinessFunctionDetector {
  BusinessFunctionDetector(this.config);

  final QualityConfig config;

  static const Set<String> _infraReceiverHints = {
    'repository',
    'repo',
    'api',
    'apiservice',
    'apiclient',
    'client',
    'datasource',
    'service',
    'usecase',
    'http',
    'dio',
  };

  List<BusinessFunction> detect({
    required String filePath,
    required ArchLayer layer,
    required ParsedFile parsed,
  }) {
    final results = <BusinessFunction>[];

    void consider(
      ParsedMethod method,
      String? className,
      List<ParamInfo> dependencies,
    ) {
      if (!_isBusinessVerb(method.name)) return;
      if (!_looksLikeBusinessLogic(method)) return;
      results.add(
        BusinessFunction(
          name: method.name,
          filePath: filePath,
          className: className,
          signature: method.signature,
          layer: layer,
          calls: method.calls,
          bodyStartLine: method.startLine,
          bodyEndLine: method.endLine,
          dependencies: dependencies,
        ),
      );
    }

    for (final cls in parsed.classes) {
      final deps = cls.fields
          .map((f) => ParamInfo(name: f.name, type: f.type))
          .toList();
      for (final method in cls.methods) {
        consider(method, cls.name, deps);
      }
    }
    for (final fn in parsed.topLevelFunctions) {
      consider(fn, null, const []);
    }

    return results;
  }

  bool _isBusinessVerb(String name) {
    if (name.startsWith('_')) {
      // Private helpers can still be business logic; strip the underscore.
      name = name.substring(1);
    }
    final lower = name.toLowerCase();
    for (final verb in config.businessVerbs) {
      if (lower == verb || lower.startsWith(verb)) return true;
    }
    return false;
  }

  bool _looksLikeBusinessLogic(ParsedMethod method) {
    if (method.isAsync) return true;
    if (method.returnType.startsWith('Future') ||
        method.returnType.startsWith('Stream')) {
      return true;
    }
    for (final call in method.calls) {
      final receiver = call.receiver?.toLowerCase() ?? '';
      for (final hint in _infraReceiverHints) {
        if (receiver.contains(hint)) return true;
      }
    }
    return false;
  }
}
