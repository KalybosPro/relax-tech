// ignore_for_file: avoid_print

import 'package:args/command_runner.dart';
import 'package:env_builder_cli/src/core/cli_colors.dart';
import 'package:env_builder_cli/src/core/core.dart';

/// Command to display version information
class VersionCommand extends Command<int> {
  @override
  String get description => 'Display version information';

  @override
  String get name => 'version';

  @override
  List<String> get aliases => ['--version', '-v'];

  @override
  Future<int> run() async {
    try {
      // Initialize colors (version command doesn't have --no-color flag)
      CliColors.setUseColors(true);

      print('${CliColors.bold(CliColors.cyan('Env Builder CLI'))} v${TextTemplates.cliVersion}');
      print('${CliColors.gray('Built with Dart SDK')} ${TextTemplates.dartSdkVersion}');
      print('');
      print(CliColors.bold('Description:'));
      print('A powerful Dart CLI tool that automates the generation and');
      print('management of environment-specific Flutter packages using Envied');
      print('for type-safe access to environment variables.');
      print('');
      print('${CliColors.bold('Homepage:')} ${CliColors.blue('https://github.com/KalybosPro/env_builder_cli')}');

      return 0;
    } catch (e) {
      print('Error retrieving version: $e');
      return 1;
    }
  }
}
