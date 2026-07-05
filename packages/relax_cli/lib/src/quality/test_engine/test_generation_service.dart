import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/quality_models.dart';
import 'test_generator.dart';

/// The plan for a test-generation run: which files would be created and which
/// already exist (and are therefore left untouched — generation is
/// non-destructive and never overwrites).
class TestGenerationPlan {
  const TestGenerationPlan({required this.toCreate, required this.skipped});

  /// Generated files that do not yet exist on disk.
  final List<GeneratedTestFile> toCreate;

  /// Expected test paths that already exist and were skipped.
  final List<String> skipped;

  bool get isEmpty => toCreate.isEmpty;
}

/// Builds and (optionally) writes test scaffolds for untested business
/// functions. Writing is non-destructive: an existing test file is never
/// overwritten.
class TestGenerationService {
  TestGenerationService({
    required this.projectRoot,
    required String packageName,
  }) : _generator = TestGenerator(packageName: packageName);

  final String projectRoot;
  final TestGenerator _generator;

  /// Computes what would be generated for the given [gaps] without writing.
  TestGenerationPlan plan(List<TestGap> gaps) {
    final toCreate = <GeneratedTestFile>[];
    final skipped = <String>[];
    final claimed = <String>{};

    for (final gap in gaps) {
      final generated = _generator.generate(gap.businessFunction);
      final abs = p.join(projectRoot, generated.filePath);
      if (File(abs).existsSync() || !claimed.add(generated.filePath)) {
        skipped.add(generated.filePath);
        continue;
      }
      toCreate.add(generated);
    }
    return TestGenerationPlan(toCreate: toCreate, skipped: skipped);
  }

  /// Writes the planned files to disk, creating directories as needed. Returns
  /// the relative paths actually written.
  List<String> write(TestGenerationPlan plan) {
    final written = <String>[];
    for (final file in plan.toCreate) {
      final abs = p.join(projectRoot, file.filePath);
      final handle = File(abs)..parent.createSync(recursive: true);
      handle.writeAsStringSync(file.content);
      written.add(file.filePath);
    }
    return written;
  }
}

/// Reads the `name:` field from `<projectRoot>/pubspec.yaml`, falling back to
/// `app` when it cannot be determined.
String readPackageName(String projectRoot) {
  final file = File(p.join(projectRoot, 'pubspec.yaml'));
  if (!file.existsSync()) return 'app';
  for (final line in file.readAsLinesSync()) {
    final match = RegExp(r'^name:\s*([A-Za-z0-9_]+)').firstMatch(line);
    if (match != null) return match.group(1)!;
  }
  return 'app';
}
