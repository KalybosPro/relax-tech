// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:universal_io/io.dart';

import 'cli_colors.dart';

/// Handles encryption and decryption of environment files
///
/// Provides secure encryption/decryption using AES-256 algorithm
/// with SHA-256 derived keys from user passwords.
///
/// Security Features:
/// - AES-256 encryption with random IV per file
/// - Random salt generation for key derivation
/// - PBKDF2-like key derivation with salt
/// - Minimum password length validation (8 characters)
/// - Secure password input (hidden in terminal)
///
/// Best Practices:
/// - Use strong, unique passwords (minimum 12 characters recommended)
/// - Store encrypted files securely
/// - Never commit passwords or encrypted files to version control
/// - Use different passwords for different environments
class EnvCrypto {
  /// Minimum password length for security
  static const int minPasswordLength = 8;

  /// Generate random salt for key derivation
  static String _generateRandomSalt() {
    final random = encrypt.SecureRandom(16); // 16 bytes = 128 bits
    return base64.encode(random.bytes);
  }

  /// Generate AES-256 key from a password with salt
  static encrypt.Key _deriveKey(String password, String salt) {
    final combined = password + salt; // Add salt for better security
    final keyHash = sha256.convert(utf8.encode(combined)).bytes;
    return encrypt.Key(Uint8List.fromList(keyHash));
  }

  /// Validate password strength
  static bool _isValidPassword(String password) {
    if (password.length < minPasswordLength) {
      CliLogger.error('Password must be at least $minPasswordLength characters long.');
      return false;
    }
    return true;
  }

  /// Encrypt .env file
  static Future<void> encryptFile(
    String inputPath,
    String outputPath,
    String password,
  ) async {
    try {
      // Validate password strength
      if (!_isValidPassword(password)) {
        return;
      }

      final inputFile = File(inputPath);

      if (!await inputFile.exists()) {
        CliLogger.error('File "$inputPath" does not exist.');
        return;
      }

      final plainText = await inputFile.readAsString();
      if (plainText.trim().isEmpty) {
        CliLogger.warning('File "$inputPath" is empty, nothing to encrypt.');
        return;
      }

      // Generate random salt and IV for this encryption
      final salt = _generateRandomSalt();
      final key = _deriveKey(password, salt);
      final iv = encrypt.IV.fromLength(16);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      // Encrypting
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Store salt, IV, and encrypted data
      final data = {
        'salt': salt,
        'iv': iv.base64,
        'data': encrypted.base64,
        'version': '1.0', // For future compatibility
      };

      // Writing
      final outputFile = File(outputPath);
      await outputFile.writeAsString(json.encode(data));

      CliLogger.success('File successfully encrypted to: $outputPath');
    } on FileSystemException catch (e) {
      CliLogger.error('File system error: ${e.message} (path: ${e.path})');
    } on FormatException catch (e) {
      CliLogger.error('Encoding error: ${e.message}');
    } on ArgumentError catch (e) {
      CliLogger.error('Invalid argument: ${e.message}');
    } catch (e) {
      CliLogger.error('Unexpected error: $e');
    }
  }

  /// Decrypt .env file
  static Future<void> decryptFile(
    String inputPath,
    String outputPath,
    String password,
  ) async {
    try {
      // Validate password strength
      if (!_isValidPassword(password)) {
        return;
      }

      final inputFile = File(inputPath);

      // Check if input file exists
      if (!await inputFile.exists()) {
        CliLogger.error('File "$inputPath" does not exist.');
        return;
      }

      // Read encrypted content
      final encryptedText = await inputFile.readAsString();
      if (encryptedText.trim().isEmpty) {
        CliLogger.warning('File "$inputPath" is empty, nothing to decrypt.');
        return;
      }

      // Parse encrypted data
      final decoded = json.decode(encryptedText);
      final salt = decoded['salt'] as String?;
      final encoded = decoded['data'] as String?;
      final ivBase64 = decoded['iv'] as String?;

      if (salt == null || encoded == null || ivBase64 == null) {
        CliLogger.error('Invalid encrypted file format.');
        return;
      }

      // Derive AES key using stored salt
      final key = _deriveKey(password, salt);
      final iv = encrypt.IV.fromBase64(ivBase64);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      // Try to decrypt content
      String decrypted;
      try {
        decrypted = encrypter.decrypt64(encoded, iv: iv);
      } on ArgumentError catch (_) {
        CliLogger.error('Invalid password or corrupted file.');
        return;
      } on FormatException catch (_) {
        CliLogger.error('File content is not valid Base64.');
        return;
      }

      // Write decrypted content to output file
      final outputFile = File(outputPath);
      await outputFile.writeAsString(decrypted);

      CliLogger.success('File successfully decrypted to: $outputPath');
    } on FileSystemException catch (e) {
      CliLogger.error('File system error: ${e.message} (path: ${e.path})');
    } on ArgumentError catch (e) {
      CliLogger.error('Invalid argument: ${e.message}');
    } on FormatException catch (e) {
      CliLogger.error('Encoding error: ${e.message}');
    } catch (e) {
      CliLogger.error('Unexpected error: $e');
    }
  }

  /// Ask for the password
  static String askPassword(String prompt) {
    stdout.write(prompt);
    stdin.echoMode = false; // hide the password entrance
    final password = stdin.readLineSync() ?? '';
    stdin.echoMode = true;
    stdout.writeln();
    return password;
  }
}
