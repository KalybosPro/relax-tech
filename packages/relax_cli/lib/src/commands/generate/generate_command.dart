import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'feature_command.dart';
import 'model_command.dart';
import 'module_command.dart';

/// Parent command for code generation: `relax generate <subcommand>`.
class GenerateCommand extends Command<int> {
  GenerateCommand({required Logger logger}) {
    addSubcommand(FeatureCommand(logger: logger));
    addSubcommand(ModuleCommand(logger: logger));
    addSubcommand(ModelCommand(logger: logger));
  }

  @override
  String get name => 'generate';

  @override
  String get description => 'Generate components inside an existing project.';

  @override
  List<String> get aliases => ['g'];
}
