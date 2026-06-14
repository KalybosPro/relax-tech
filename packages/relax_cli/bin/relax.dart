import 'dart:io';

import 'package:relax_cli/src/cli_runner.dart';

Future<void> main(List<String> args) async {
  final exitCode = await RelaxCommandRunner().run(args);
  await stdout.flush();
  exit(exitCode);
}
