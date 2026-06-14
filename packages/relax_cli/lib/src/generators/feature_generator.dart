import 'dart:io';

import 'package:mason/mason.dart';

import '../models/architecture.dart';
import '../templates/feature_template.dart';

/// Generates a new feature module inside an existing Flutter project.
class FeatureGenerator {
  const FeatureGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generates the feature files inside `lib/features/` of [projectDir].
  ///
  /// Returns the list of generated files.
  Future<List<GeneratedFile>> generate({
    required String featureName,
    required Architecture architecture,
    required Directory projectDir,
  }) async {
    final files = switch (architecture) {
      Architecture.bloc => FeatureTemplate.bloc,
      Architecture.provider => FeatureTemplate.provider,
      Architecture.riverpod => FeatureTemplate.riverpod,
      Architecture.getx => FeatureTemplate.getx,
    };

    final generator = MasonGenerator(
      '${architecture.name}_feature',
      '${architecture.label} feature module.',
      files: files,
      vars: ['feature_name'],
    );

    final featuresDir = Directory('${projectDir.path}/lib/features');
    final target = DirectoryGeneratorTarget(featuresDir);

    return generator.generate(
      target,
      vars: <String, dynamic>{'feature_name': featureName},
      logger: _logger,
    );
  }
}
