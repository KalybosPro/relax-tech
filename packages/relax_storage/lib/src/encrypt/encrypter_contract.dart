import 'package:encrypt/encrypt.dart' as enc;

/// Contract for encryption operations.
///
/// Defines the interface for encrypting and decrypting data using
/// a key-based encryption scheme.
///
/// Implement this interface to provide a custom encryption strategy
/// to [RelaxStorage].
abstract class IEncrypter {
  /// Derives an AES encryption key from the given [key] string.
  ///
  /// Uses SHA-256 hashing with a salt to produce a 256-bit key.
  /// An optional [customSalt] can override the default salt.
  enc.Key deriveKey(String key, {String? customSalt});

  /// Encrypts [data] using the provided [key].
  ///
  /// Returns a string in the format `"IV_BASE64:ENCRYPTED_DATA_BASE64"`.
  /// A new random IV is generated for each call, so encrypting the same
  /// data twice will produce different outputs.
  String encrypt<T>(T data, String key);

  /// Decrypts an [encryptedText] payload using the provided [key].
  ///
  /// The [encryptedText] must be in the format `"IV_BASE64:ENCRYPTED_DATA_BASE64"`
  /// as produced by [encrypt].
  ///
  /// Throws [ArgumentError] if the payload format is invalid.
  String decrypt(String encryptedText, String key);
}
