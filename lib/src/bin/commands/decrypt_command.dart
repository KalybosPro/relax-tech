import 'package:args/command_runner.dart';

import '../../core/cli_colors.dart';
import '../../core/env_crypto.dart';

// ignore_for_file: avoid_print

/// Command for decrypting .env files
class DecryptCommand extends Command<int> {

  DecryptCommand() {
    argParser.addOption('password', abbr: 'p', help: 'Secret key for decryption', mandatory: true);
  }
  @override
  String get description => 'Decrypt .env.encrypted files';

  @override
  String get name => 'decrypt';

  @override
  Future<int> run() async {
    try {
      final password = argResults!['password'] as String;
      final input = argResults!.rest.isNotEmpty ? argResults!.rest[0] : '.env.encrypted';
      final output = argResults!.rest.length > 1 ? argResults!.rest[1] : '.env.decrypted';

      await EnvCrypto.decryptFile(input, output, password);
      CliLogger.success('Decryption completed successfully');
      return 0;
    } catch (e) {
      CliLogger.error('Decryption failed: $e');
      return 64;
    }
  }
}
