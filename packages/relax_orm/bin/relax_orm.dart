// RelaxORM command-line entry point.
//
// A thin, dependency-free wrapper around `build_runner` so codegen has one
// obvious command — and so seeder generation can be toggled without editing
// build.yaml:
//
//   dart run relax_orm            # generate schemas
//   dart run relax_orm --seed     # generate schemas + seeders
//
// `dart run build_runner build` keeps working exactly as before.
import 'dart:io';

/// Builder key of the relax_orm generator, as declared in
/// `relax_orm_generator/build.yaml`.
const _builderKey = 'relax_orm_generator:relax_orm';

const _usage =
    '''
RelaxORM codegen — a wrapper around build_runner.

Usage: dart run relax_orm [command] [options]

Commands:
  build            Generate once (default).
  watch            Generate and keep watching for changes.
  clean            Delete build_runner's cache and generated outputs.

Options:
  --seed           Also generate a TableSeeder for every @RelaxTable model.
                   Models annotated with @RelaxSeed are generated either way;
                   @RelaxSeed(enabled: false) opts a model out.
  --seed-count=N   Default number of rows generated seeders insert (default 10).
                   Overridden per model by @RelaxSeed(count: N).
  -h, --help       Show this help.

Anything after `--` is forwarded to build_runner verbatim:
  dart run relax_orm --seed -- --verbose

Equivalent commands:
  dart run relax_orm            ==  dart run build_runner build
  dart run relax_orm --seed     ==  dart run build_runner build \\
                                      --define="$_builderKey=seed=true"
''';

Future<void> main(List<String> arguments) async {
  final args = _Args.parse(arguments);

  if (args.help) {
    stdout.writeln(_usage);
    return;
  }
  if (args.error != null) {
    stderr.writeln('relax_orm: ${args.error}\n');
    stderr.writeln(_usage);
    exitCode = 64; // EX_USAGE
    return;
  }

  final buildArgs = <String>['run', 'build_runner', args.command];

  if (args.command != 'clean') {
    if (args.seed) {
      buildArgs.add('--define=$_builderKey=seed=true');
    }
    if (args.seedCount != null) {
      buildArgs.add('--define=$_builderKey=seed_count=${args.seedCount}');
    }
  }
  buildArgs.addAll(args.forwarded);

  stdout.writeln('relax_orm: dart ${buildArgs.join(' ')}');
  if (args.seed && args.command != 'clean') {
    stdout.writeln('relax_orm: seeder generation enabled');
  }

  final process = await Process.start(
    Platform.resolvedExecutable,
    buildArgs,
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await process.exitCode;
}

/// Parsed command line. Hand-rolled so `bin/` stays dependency-free — this
/// script must run in any app that depends on relax_orm.
class _Args {
  _Args({
    required this.command,
    required this.seed,
    required this.seedCount,
    required this.forwarded,
    required this.help,
    this.error,
  });

  final String command;
  final bool seed;
  final int? seedCount;
  final List<String> forwarded;
  final bool help;
  final String? error;

  static const _commands = {'build', 'watch', 'clean'};

  static _Args parse(List<String> arguments) {
    var command = 'build';
    var commandSeen = false;
    var seed = false;
    int? seedCount;
    var help = false;
    final forwarded = <String>[];
    String? error;

    for (var i = 0; i < arguments.length; i++) {
      final arg = arguments[i];

      if (arg == '--') {
        forwarded.addAll(arguments.sublist(i + 1));
        break;
      }
      if (arg == '-h' || arg == '--help') {
        help = true;
        continue;
      }
      if (arg == '--seed') {
        seed = true;
        continue;
      }
      if (arg.startsWith('--seed-count=')) {
        final raw = arg.substring('--seed-count='.length);
        final value = int.tryParse(raw);
        if (value == null || value < 0) {
          error ??= '--seed-count expects a non-negative integer, got "$raw".';
          continue;
        }
        seedCount = value;
        // A row count only makes sense when seeders are generated.
        seed = true;
        continue;
      }
      if (!arg.startsWith('-') && !commandSeen) {
        if (!_commands.contains(arg)) {
          error ??=
              'unknown command "$arg". '
              'Expected one of: ${_commands.join(', ')}.';
          continue;
        }
        command = arg;
        commandSeen = true;
        continue;
      }

      error ??=
          'unknown option "$arg". '
          'Pass build_runner options after `--`.';
    }

    return _Args(
      command: command,
      seed: seed,
      seedCount: seedCount,
      forwarded: forwarded,
      help: help,
      error: error,
    );
  }
}
