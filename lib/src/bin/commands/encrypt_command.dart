import 'package:args/command_runner.dart';

import '../../core/cli_colors.dart';
import '../../core/env_crypto.dart';

// ignore_for_file: avoid_print

/// Command for encrypting .env files
class EncryptCommand extends Command<int> {

  EncryptCommand() {
    argParser.addOption('password', abbr: 'p', help: 'Secret key for encryption', mandatory: true);
  }
  @override
  String get description => 'Encrypt .env files';

  @override
  String get name => 'encrypt';

  @override
  Future<int> run() async {
    try {
      final password = argResults!['password'] as String;
      final input = argResults!.rest.isNotEmpty ? argResults!.rest[0] : '.env';
      final output = argResults!.rest.length > 1 ? argResults!.rest[1] : '$input.encrypted';

      await EnvCrypto.encryptFile(input, output, password);
      CliLogger.success('Encryption completed successfully');
      return 0;
    } catch (e) {
      CliLogger.error('Encryption failed: $e');
      return 64;
    }
  }
}
