import 'dart:io';

import 'package:mason/mason.dart';

import '../templates/model_template.dart';

/// Generates a RelaxORM model class inside an existing Flutter project.
class ModelGenerator {
  /// Creates a [ModelGenerator] with the given [logger].
  const ModelGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generates the model file inside [outputDir].
  Future<List<GeneratedFile>> generate({
    required String modelName,
    required Directory outputDir,
  }) async {
    final generator = MasonGenerator(
      'model',
      'RelaxORM model class.',
      files: ModelTemplate.files,
      vars: ['model_name'],
    );

    final target = DirectoryGeneratorTarget(outputDir);

    return generator.generate(
      target,
      vars: <String, dynamic>{'model_name': modelName},
      logger: _logger,
    );
  }
}
