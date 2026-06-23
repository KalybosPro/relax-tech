import 'dart:io';

import 'package:mason/mason.dart';

import '../models/architecture.dart';
import '../templates/page_template.dart';

/// Generates a Page + View pair inside an existing feature folder.
class PageGenerator {
  const PageGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generates page files inside `lib/features/[folderName]/view/` of
  /// [projectDir].
  ///
  /// [folderName] is the feature path under `lib/features/` and may be nested
  /// (e.g. `auth/login`). [featureName] is the leaf segment used to derive class
  /// names (e.g. the bloc/notifier referenced by the page).
  Future<List<GeneratedFile>> generate({
    required String folderName,
    required String featureName,
    required String pageName,
    required Architecture architecture,
    required Directory projectDir,
  }) async {
    final files = switch (architecture) {
      Architecture.bloc => PageTemplate.bloc,
      Architecture.provider => PageTemplate.provider,
      Architecture.riverpod => PageTemplate.riverpod,
      Architecture.getx => PageTemplate.getx,
    };

    final generator = MasonGenerator(
      '${architecture.name}_page',
      '${architecture.label} page.',
      files: files,
      vars: ['feature_name', 'page_name'],
    );

    final featureDir = Directory('${projectDir.path}/lib/features/$folderName');
    final target = DirectoryGeneratorTarget(featureDir);

    return generator.generate(
      target,
      vars: <String, dynamic>{
        'feature_name': featureName,
        'page_name': pageName,
      },
      logger: _logger,
    );
  }
}
