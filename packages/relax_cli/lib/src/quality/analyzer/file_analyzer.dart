import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../config/quality_config.dart';
import '../models/quality_models.dart';
import 'business_function_detector.dart';
import 'dart_parser.dart';
import 'layer_classifier.dart';
import 'state_management_detector.dart';

/// A fully analyzed file: its derived [DartFileInfo] plus the raw [ParsedFile]
/// structure needed by quality rules.
class AnalyzedFile {
  AnalyzedFile({
    required this.relPath,
    required this.absPath,
    required this.info,
    required this.parsed,
  });

  /// Path relative to the project root, using forward slashes.
  final String relPath;
  final String absPath;
  final DartFileInfo info;
  final ParsedFile parsed;
}

/// Orchestrates parsing + classification for a single file, producing an
/// [AnalyzedFile]. Returns `null` when the file cannot be read.
class FileAnalyzer {
  FileAnalyzer({required this.projectRoot, required this.config})
    : _parser = DartParser(),
      _layers = LayerClassifier(),
      _stateMgmt = StateManagementDetector(),
      _business = BusinessFunctionDetector(config);

  final String projectRoot;
  final QualityConfig config;

  final DartParser _parser;
  final LayerClassifier _layers;
  final StateManagementDetector _stateMgmt;
  final BusinessFunctionDetector _business;

  AnalyzedFile? analyze(String absPath) {
    final file = File(absPath);
    final String content;
    try {
      content = file.readAsStringSync();
    } on FileSystemException {
      return null;
    }

    final relPath = p
        .relative(absPath, from: projectRoot)
        .replaceAll(r'\', '/');
    final parsed = _parser.parse(content);
    final layer = _layers.classify(relPath, parsed);
    final sm = _stateMgmt.detect(parsed);
    final businessFns = _business.detect(
      filePath: relPath,
      layer: layer,
      parsed: parsed,
    );

    final info = DartFileInfo(
      path: relPath,
      hash: sha1.convert(utf8.encode(content)).toString(),
      layer: layer,
      stateManagement: sm,
      classNames: parsed.classes.map((c) => c.name).toList(),
      imports: parsed.imports,
      lineCount: parsed.lineCount,
      businessFunctions: businessFns,
    );

    return AnalyzedFile(
      relPath: relPath,
      absPath: absPath,
      info: info,
      parsed: parsed,
    );
  }
}
