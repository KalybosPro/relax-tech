import 'dart:io';

import 'package:path/path.dart' as p;

import '../analyzer/file_analyzer.dart';
import '../diff/patch_journal.dart';
import '../models/quality_models.dart';
import 'usecase_detector.dart';
import 'usecase_generator.dart';

/// The plan for a UseCase-generation run.
class UseCaseGenerationPlan {
  const UseCaseGenerationPlan({
    required this.toCreate,
    required this.skippedExisting,
    required this.alreadyImplemented,
  });

  /// UseCase files that would be created.
  final List<GeneratedUseCase> toCreate;

  /// Suggested paths that already exist on disk (left untouched).
  final List<String> skippedExisting;

  /// Business functions that already have a UseCase (by class-name match).
  final List<String> alreadyImplemented;

  bool get isEmpty => toCreate.isEmpty;
}

/// Detects missing UseCases for a project's business functions and generates
/// them as **new files only**. Never rewrites existing source or call sites.
class UseCaseService {
  UseCaseService({required this.projectRoot})
    : _detector = UseCaseDetector(),
      _generator = UseCaseGenerator();

  final String projectRoot;
  final UseCaseDetector _detector;
  final UseCaseGenerator _generator;

  /// Layers whose business functions are candidates for extraction. Functions
  /// already inside the UseCase layer are skipped.
  static const Set<ArchLayer> _eligibleLayers = {
    ArchLayer.controller,
    ArchLayer.unknown,
  };

  /// Computes what would be generated from the analyzed files, without writing.
  UseCaseGenerationPlan plan(List<AnalyzedFile> analyzedFiles) {
    final toCreate = <GeneratedUseCase>[];
    final skipped = <String>[];
    final already = <String>[];
    final claimed = <String>{};
    final seenFn = <String>{};

    for (final file in analyzedFiles) {
      if (file.info.isTest) continue;
      for (final fn in file.info.businessFunctions) {
        if (!_eligibleLayers.contains(fn.layer)) continue;
        final key = '${fn.filePath}#${fn.className}.${fn.name}';
        if (!seenFn.add(key)) continue;

        final candidate = _detector.detect(fn, analyzedFiles);
        if (candidate.existingUseCaseFound) {
          already.add(
            '${candidate.suggestedClassName} '
            '(${candidate.matchedClassNames.join(', ')})',
          );
          continue;
        }

        final generated = _generator.generate(candidate);
        final abs = p.join(projectRoot, generated.filePath);
        if (File(abs).existsSync() || !claimed.add(generated.filePath)) {
          skipped.add(generated.filePath);
          continue;
        }
        toCreate.add(generated);
      }
    }

    return UseCaseGenerationPlan(
      toCreate: toCreate,
      skippedExisting: skipped,
      alreadyImplemented: already,
    );
  }

  /// Journals the proposed files (reversible patch) and writes them to disk.
  /// Returns the relative paths written and the patch directory.
  ({List<String> written, String patchDir}) write(UseCaseGenerationPlan plan) {
    final proposed = <ProposedFile>[
      for (final g in plan.toCreate) (relPath: g.filePath, content: g.content),
    ];
    final patchDir = PatchJournal(
      projectRoot: projectRoot,
    ).journal(proposed, action: 'generate-usecases');

    final written = <String>[];
    for (final g in plan.toCreate) {
      final handle = File(p.join(projectRoot, g.filePath))
        ..parent.createSync(recursive: true);
      handle.writeAsStringSync(g.content);
      written.add(g.filePath);
    }
    return (written: written, patchDir: patchDir);
  }

  /// The combined unified diff for the plan, for `--dry-run` preview.
  String diff(UseCaseGenerationPlan plan) => PatchJournal.buildDiff([
    for (final g in plan.toCreate) (relPath: g.filePath, content: g.content),
  ]);
}
