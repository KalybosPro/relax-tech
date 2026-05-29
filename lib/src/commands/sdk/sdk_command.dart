import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'sdk_config_command.dart';
import 'sdk_dart_command.dart';
import 'sdk_destroy_command.dart';
import 'sdk_doctor_command.dart';
import 'sdk_exec_command.dart';
import 'sdk_flutter_command.dart';
import 'sdk_global_command.dart';
import 'sdk_install_command.dart';
import 'sdk_list_command.dart';
import 'sdk_releases_command.dart';
import 'sdk_remove_command.dart';
import 'sdk_spawn_command.dart';
import 'sdk_use_command.dart';

/// Parent command for Flutter SDK version management.
class SdkCommand extends Command<int> {
  SdkCommand({required Logger logger}) {
    addSubcommand(SdkInstallCommand(logger: logger));
    addSubcommand(SdkUseCommand(logger: logger));
    addSubcommand(SdkListCommand(logger: logger));
    addSubcommand(SdkReleasesCommand(logger: logger));
    addSubcommand(SdkRemoveCommand(logger: logger));
    addSubcommand(SdkGlobalCommand(logger: logger));
    addSubcommand(SdkFlutterCommand(logger: logger));
    addSubcommand(SdkDartCommand(logger: logger));
    addSubcommand(SdkDoctorCommand(logger: logger));
    addSubcommand(SdkConfigCommand(logger: logger));
    addSubcommand(SdkExecCommand(logger: logger));
    addSubcommand(SdkSpawnCommand(logger: logger));
    addSubcommand(SdkDestroyCommand(logger: logger));
  }

  @override
  String get name => 'sdk';

  @override
  String get description => 'Manage Flutter SDK versions.';

  @override
  Future<int>? run() => null;
}
