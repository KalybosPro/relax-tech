/// A CLI tool to generate Flutter projects with clean architecture,
/// multiple state management options, and RelaxORM integration.
///
/// Install globally with:
/// ```bash
/// dart pub global activate relax_cli
/// ```
///
/// Usage:
/// ```bash
/// relax create my_app -a bloc
/// relax generate module user
/// relax generate model product
/// relax doctor
/// ```
library;

export 'src/cli_runner.dart';
export 'src/commands/commands.dart';
export 'src/generators/generators.dart';
export 'src/models/architecture.dart';
export 'src/utils/architecture_detector.dart';
export 'src/version.dart';
