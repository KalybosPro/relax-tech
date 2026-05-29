import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/commands.dart';
import 'version.dart';

/// The command runner for the relax CLI.
class RelaxCommandRunner extends CommandRunner<int> {
  /// Creates the relax CLI command runner.
  ///
  /// If no [logger] is provided, a default [Logger] is used.
  RelaxCommandRunner({Logger? logger})
      : _logger = logger ?? Logger(),
        super(
          'relax',
          'Generate Flutter projects with clean architecture.\n'
              'Version: $version',
        ) {
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the current version.',
    );
    addCommand(CreateCommand(logger: _logger));
    addCommand(DoctorCommand(logger: _logger));
    addCommand(GenerateCommand(logger: _logger));
    addCommand(CleanCommand(logger: _logger));
    addCommand(PubCommand(logger: _logger));
    addCommand(BuildCommand(logger: _logger));
    addCommand(SdkCommand(logger: _logger));
  }

  final Logger _logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);

      if (argResults['version'] == true) {
        _logger.info('relax v$version');
        return ExitCode.success.code;
      }

      return await runCommand(argResults) ?? ExitCode.success.code;
    } on FormatException catch (e) {
      _logger.err(e.message);
      _logger.info('');
      _logger.info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger.err(e.message);
      _logger.info('');
      _logger.info(e.usage);
      return ExitCode.usage.code;
    } catch (e) {
      _logger.err('$e');
      return ExitCode.software.code;
    }
  }

  @override
  void printUsage() => _logger.info(usage);
}
