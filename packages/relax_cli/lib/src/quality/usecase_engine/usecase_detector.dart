import '../analyzer/file_analyzer.dart';
import '../models/quality_models.dart';

/// Detects whether a business function already has a corresponding UseCase.
///
/// Matching is name-based and tolerant of casing (`UseCase` vs `Usecase`) and
/// an `Abstract` prefix, mirroring the specification's `detectUseCase`.
class UseCaseDetector {
  UseCaseCandidate detect(BusinessFunction fn, List<AnalyzedFile> allFiles) {
    final base = _pascal(fn.name);
    final patterns = <String>[
      '${base}UseCase',
      '${base}Usecase',
      'Abstract${base}UseCase',
      'Abstract${base}Usecase',
      'I${base}UseCase',
    ].map(_normalize).toSet();

    final matched = <String>[];
    for (final file in allFiles) {
      for (final className in file.info.classNames) {
        if (patterns.contains(_normalize(className))) {
          matched.add(className);
        }
      }
    }

    return UseCaseCandidate(
      businessFunction: fn,
      existingUseCaseFound: matched.isNotEmpty,
      matchedClassNames: matched,
      suggestedFileName: '${_snake(fn.name)}_usecase.dart',
      suggestedClassName: '${base}UseCase',
    );
  }

  /// Lower-cases and strips a leading `abstract`/`i` marker + all separators so
  /// `LoginUseCase`, `LoginUsecase`, and `AbstractLoginUseCase` compare equal.
  String _normalize(String name) {
    var n = name.toLowerCase().replaceAll(RegExp('[_ ]'), '');
    if (n.startsWith('abstract')) n = n.substring('abstract'.length);
    return n;
  }

  String _pascal(String s) {
    final cleaned = s.startsWith('_') ? s.substring(1) : s;
    if (cleaned.isEmpty) return cleaned;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  String _snake(String name) {
    final cleaned = name.startsWith('_') ? name.substring(1) : name;
    return cleaned
        .replaceAllMapped(
          RegExp('[A-Z]'),
          (m) => '_${m.group(0)!.toLowerCase()}',
        )
        .replaceAll(RegExp('^_'), '')
        .replaceAll(RegExp('_+'), '_');
  }
}
