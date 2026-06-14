import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:relax_storage/src/encrypt/encrypter_contract.dart';

/// Default implementation of [IEncrypter] using AES-CBC encryption.
///
/// Uses SHA-256 to derive a 256-bit key from a password + salt combination,
/// and AES-CBC with a random 128-bit IV for each encryption operation.
///
/// Example:
/// ```dart
/// final encrypter = Encrypter(salt: 'my-salt');
/// final encrypted = encrypter.encrypt('Hello', 'my-key');
/// final decrypted = encrypter.decrypt(encrypted, 'my-key');
/// print(decrypted); // Hello
/// ```
class Encrypter implements IEncrypter {
  /// Creates an [Encrypter] with the given [salt].
  ///
  /// The [salt] is combined with the encryption key before hashing
  /// to produce the AES key. Defaults to `'encryption_default_salt'`.
  Encrypter({this.salt = 'encryption_default_salt'});

  /// The salt used for key derivation.
  final String salt;

  @override
  enc.Key deriveKey(String key, {String? customSalt}) {
    final combined = key + (customSalt ?? salt);
    final keyHash = sha256.convert(utf8.encode(combined)).bytes;
    return enc.Key(Uint8List.fromList(keyHash));
  }

  @override
  String encrypt<T>(T data, String key) {
    final text = data is String ? data : data.toString();
    final newKey = deriveKey(key);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(newKey, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(text, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  @override
  String decrypt(String payload, String key) {
    final parts = payload.split(':');
    if (parts.length != 2) {
      throw ArgumentError('Invalid encrypted payload format');
    }
    final iv = enc.IV.fromBase64(parts[0]);
    final encrypted = enc.Encrypted.fromBase64(parts[1]);
    final newKey = deriveKey(key);
    final encrypter = enc.Encrypter(enc.AES(newKey, mode: enc.AESMode.cbc));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
