/// Contract for encrypted key-value storage operations.
///
/// Defines the CRUD interface for storing, reading, and deleting
/// encrypted data. Implement this interface to provide a custom
/// storage backend.
abstract class IRelaxStorage {
  /// Saves a [data] value of type [T] associated with the given [key].
  ///
  /// The data is serialized to JSON, encrypted, and then persisted.
  /// If a value already exists for the [key], it will be overwritten.
  ///
  /// Example:
  /// ```dart
  /// await storage.save<String>('username', 'john_doe');
  /// await storage.save<int>('age', 25);
  /// ```
  Future<void> save<T>(String key, T data);

  /// Reads and decrypts the value of type [T] associated with the given [key].
  ///
  /// Returns `null` if no value exists for the [key].
  /// Supported types: [String], [int], [double], [bool], and any
  /// JSON-serializable type.
  ///
  /// Example:
  /// ```dart
  /// final username = storage.read<String>('username');
  /// final age = storage.read<int>('age');
  /// ```
  T? read<T>(String key);

  /// Deletes the value associated with the given [key].
  ///
  /// If no value exists for the [key], this is a no-op.
  Future<void> delete(String key);

  /// Clears all stored key-value pairs.
  ///
  /// Removes all data from the storage, effectively resetting it
  /// to an empty state.
  Future<void> clear();
}
