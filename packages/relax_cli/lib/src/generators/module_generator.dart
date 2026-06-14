import 'dart:io';

import 'package:mason/mason.dart';

import '../templates/module_template.dart';

/// Generates a domain/data module inside an existing Flutter project.
class ModuleGenerator {
  /// Creates a [ModuleGenerator] with the given [logger].
  const ModuleGenerator({required Logger logger}) : _logger = logger;

  final Logger _logger;

  /// Generates the module files inside [outputDir].
  Future<List<GeneratedFile>> generate({
    required String moduleName,
    required Directory outputDir,
  }) async {
    final generator = MasonGenerator(
      'module',
      'Domain/data module.',
      files: ModuleTemplate.files,
      vars: ['module_name'],
    );

    final target = DirectoryGeneratorTarget(outputDir);

    return generator.generate(
      target,
      vars: <String, dynamic>{'module_name': moduleName},
      logger: _logger,
    );
  }
}
