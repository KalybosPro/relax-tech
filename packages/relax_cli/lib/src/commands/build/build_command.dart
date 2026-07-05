import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'build_aab_command.dart';
import 'build_apk_command.dart';

/// Parent command that groups Flutter build subcommands.
class BuildCommand extends Command<int> {
  BuildCommand({required Logger logger}) {
    addSubcommand(BuildApkCommand(logger: logger));
    addSubcommand(BuildAabCommand(logger: logger));
  }

  @override
  String get name => 'build';

  @override
  List<String> get aliases => ['b'];

  @override
  String get description =>
      'Build release artifacts for a Flutter project (apk, aab).';
}
