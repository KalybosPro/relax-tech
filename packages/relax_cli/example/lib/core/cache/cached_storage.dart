import 'package:env/env.dart';
import 'package:relax_storage/relax_storage.dart';

/// Small abstraction around local secure storage used by the app.
///
/// `CachedStorage` centralizes read/write access to cached values so the rest
/// of the codebase does not depend directly on the storage package. It is
/// currently used to persist the authentication token in encrypted storage.
///
/// Example:
///
/// ```dart
/// final storage = getIt<CachedStorage>();
///
/// // Save the token
/// await storage.setToken('eyJhbGciOiJIUzI1NiIs');
///
/// // Read the token
/// final token = storage.token;
/// ```
class CachedStorage {

  CachedStorage(EnvValue env) : box = RelaxStorage(env(Env.encryptionKey));

  final RelaxStorage box;

  Future<void> setToken(String token) =>
      box.save<String>('TOKENDATASTORAGEKEY', token);

  String? get token => box.read<String>('TOKENDATASTORAGEKEY');
}
