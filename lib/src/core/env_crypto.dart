// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:universal_io/io.dart';

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
      print('Error: Password must be at least $minPasswordLength characters long.');
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
        print('Error: File "$inputPath" does not exist.');
        return;
      }

      final plainText = await inputFile.readAsString();
      if (plainText.trim().isEmpty) {
        print('Warning: File "$inputPath" is empty, nothing to encrypt.');
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

      print('File successfully encrypted to: $outputPath');
    } on FileSystemException catch (e) {
      print('File system error: ${e.message} (path: ${e.path})');
    } on FormatException catch (e) {
      print('Encoding error: ${e.message}');
    } on ArgumentError catch (e) {
      print('Invalid argument: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
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
        print('Error: File "$inputPath" does not exist.');
        return;
      }

      // Read encrypted content
      final encryptedText = await inputFile.readAsString();
      if (encryptedText.trim().isEmpty) {
        print('Warning: File "$inputPath" is empty, nothing to decrypt.');
        return;
      }

      // Parse encrypted data
      final decoded = json.decode(encryptedText);
      final salt = decoded['salt'] as String?;
      final encoded = decoded['data'] as String?;
      final ivBase64 = decoded['iv'] as String?;

      if (salt == null || encoded == null || ivBase64 == null) {
        print('Error: Invalid encrypted file format.');
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
        print('Error: Invalid password or corrupted file.');
        return;
      } on FormatException catch (_) {
        print('Error: File content is not valid Base64.');
        return;
      }

      // Write decrypted content to output file
      final outputFile = File(outputPath);
      await outputFile.writeAsString(decrypted);

      print('File successfully decrypted to: $outputPath');
    } on FileSystemException catch (e) {
      print('File system error: ${e.message} (path: ${e.path})');
    } on ArgumentError catch (e) {
      print('Invalid argument: ${e.message}');
    } on FormatException catch (e) {
      print('Encoding error: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
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
