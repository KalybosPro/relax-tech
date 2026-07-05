import '../analyzer/file_analyzer.dart';
import '../models/quality_models.dart';

/// Detects architecture violations against a clean-architecture flow:
/// UI → Controller → UseCase → Repository → Datasource → API.
///
/// Scope (MVP): the two highest-signal violations from the spec —
/// `controller_to_api` (a controller talking to an API/datasource/http client
/// directly, skipping the repository) and `missing_repository` (a project with
/// controllers doing data work but no repository layer at all).
class ArchitectureAnalyzer {
  static const Set<String> _apiReceiverHints = {
    'api',
    'apiservice',
    'apiclient',
    'client',
    'datasource',
    'http',
    'dio',
    'httpclient',
  };

  List<ArchitectureViolation> analyze(List<AnalyzedFile> files) {
    final violations = <ArchitectureViolation>[];

    final hasRepositoryLayer = files.any(
      (f) => !f.info.isTest && f.info.layer == ArchLayer.repository,
    );

    var controllersDoingDataWork = 0;

    for (final file in files) {
      if (file.info.isTest) continue;
      if (file.info.layer != ArchLayer.controller) continue;

      var directApiCalls = 0;
      final functionNames = <String>{};

      for (final cls in file.parsed.classes) {
        for (final method in cls.methods) {
          for (final call in method.calls) {
            final receiver = call.receiver?.toLowerCase() ?? '';
            if (receiver.isEmpty) continue;
            final normalized = receiver
                .replaceAll('_', '')
                .replaceAll('this.', '');
            if (_apiReceiverHints.any(normalized.contains)) {
              directApiCalls++;
              functionNames.add(method.name);
            }
          }
        }
      }

      if (directApiCalls > 0) {
        controllersDoingDataWork++;
        violations.add(
          ArchitectureViolation(
            type: 'controller_to_api',
            filePath: file.relPath,
            functionName: functionNames.join(', '),
            message:
                'Controller → API: ${file.info.classNames.join(', ')} calls an '
                'API/datasource directly, bypassing a repository.',
            occurrences: directApiCalls,
            severity: Severity.error,
          ),
        );
      }
    }

    if (!hasRepositoryLayer && controllersDoingDataWork > 0) {
      violations.add(
        ArchitectureViolation(
          type: 'missing_repository',
          filePath: 'lib/',
          functionName: '',
          message:
              'Repository missing: $controllersDoingDataWork controller(s) '
              'perform data access but no repository layer was found.',
          occurrences: controllersDoingDataWork,
          severity: Severity.warning,
        ),
      );
    }

    return violations;
  }
}
