import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../encrypt/encrypter_contract.dart';
import '../encrypt/encrypter_impl.dart';
import 'relax_storage_contract.dart';

/// Encrypted key-value storage built on top of [GetStorage].
///
/// All data is encrypted using AES-CBC before being persisted, and
/// automatically decrypted when read back. Each write uses a unique
/// random IV, ensuring that storing the same value twice produces
/// different ciphertexts.
///
/// ## Usage
///
/// ```dart
/// // Initialize once (typically in main)
/// await RelaxStorage.init();
///
/// // Create an instance
/// final storage = RelaxStorage('my-secret-key');
///
/// // Store data
/// await storage.save<String>('token', 'abc123');
/// await storage.save<int>('counter', 42);
///
/// // Read data
/// final token = storage.read<String>('token'); // 'abc123'
/// final counter = storage.read<int>('counter'); // 42
///
/// // Delete data
/// await storage.delete('token');
///
/// // Clear all data
/// await storage.clear();
/// ```
class RelaxStorage implements IRelaxStorage {
  /// Creates a [RelaxStorage] instance with an optional [encryptionKey].
  ///
  /// If no [encryptionKey] is provided, a default key is used.
  /// For production use, always provide a unique encryption key.
  factory RelaxStorage([
    String? encryptionKey,
    String container = 'RelaxStorage',
    String? path,
    Map<String, dynamic>? initialData,
  ]) => RelaxStorage._internal(container, path, initialData, encryptionKey);

  RelaxStorage._internal([
    String container = 'RelaxStorage',
    String? path,
    Map<String, dynamic>? initialData,
    String? encryptionKey,
  ]) {
    _box = GetStorage(container, path, initialData);
    _encryptionKey = encryptionKey ?? 'encryption_default_salt';
  }

  late final GetStorage _box;
  late final String _encryptionKey;

  /// The encrypter used for encryption and decryption operations.
  IEncrypter get encrypt => Encrypter(salt: _encryptionKey);

  /// Initializes the underlying [GetStorage] engine.
  ///
  /// Must be called once before using any [RelaxStorage] instance,
  /// typically in the app's `main()` function.
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await RelaxStorage.init();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> init([String container = 'RelaxStorage']) async {
    await GetStorage.init(container);
  }

  @override
  Future<void> clear() => _box.erase();

  @override
  Future<void> delete(String key) => _box.remove(key);

  @override
  T? read<T>(String key) {
    final encrypted = _box.read(key);
    if (encrypted == null) return null;

    final decrypted = encrypt.decrypt(encrypted, _encryptionKey);
    final map = jsonDecode(decrypted);
    final value = map['value'];

    if (T == String) {
      return (value?.toString() ?? '') as T;
    }
    if (T == int) {
      return (value is num
              ? value.toInt()
              : int.tryParse(value.toString()) ?? 0)
          as T;
    }
    if (T == double) {
      return (value is num
              ? value.toDouble()
              : double.tryParse(value.toString()) ?? 0.0)
          as T;
    }
    if (T == bool) {
      return (value is bool ? value : value.toString() == 'true') as T;
    }

    return value as T;
  }

  @override
  Future<void> save<T>(String key, T data) async {
    final payload = {'type': T.toString(), 'value': data};
    final encrypted = encrypt.encrypt(jsonEncode(payload), _encryptionKey);
    return await _box.write(key, encrypted);
  }
}
