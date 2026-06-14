import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'pub_add_command.dart';
import 'pub_get_command.dart';

/// Parent command that groups Flutter pub subcommands.
class PubCommand extends Command<int> {
  PubCommand({required Logger logger}) {
    addSubcommand(PubGetCommand(logger: logger));
    addSubcommand(PubAddCommand(logger: logger));
  }

  @override
  String get name => 'pub';

  @override
  String get description => 'Flutter pub commands (get, add).';
}
