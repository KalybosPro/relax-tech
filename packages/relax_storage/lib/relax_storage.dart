/// A secure Flutter storage package with AES-CBC encryption.
///
/// RelaxStorage provides encrypted key-value storage built on top of
/// [GetStorage](https://pub.dev/packages/get_storage), using AES-CBC
/// encryption with SHA-256 key derivation and random IV generation.
///
/// ## Quick Start
///
/// ```dart
/// // Initialize storage
/// await RelaxStorage.init();
///
/// // Create an instance with an encryption key
/// final storage = RelaxStorage('my-secret-key');
///
/// // Save and read data
/// await storage.save<String>('token', 'abc123');
/// final token = storage.read<String>('token');
/// ```
library;

export 'src/encrypt/encrypter_contract.dart';
export 'src/encrypt/encrypter_impl.dart';
export 'src/storage/relax_storage_contract.dart';
export 'src/storage/relax_storage_impl.dart';
