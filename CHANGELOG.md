## 1.0.1

- Allow users to define a custom `container`, `path`, and `initialData` when creating storage.

## 1.0.0

* Initial stable release.
* AES-CBC encrypted key-value storage with SHA-256 key derivation.
* Random IV generation for each write operation.
* Support for `String`, `int`, `double`, `bool`, and JSON-serializable types.
* Built on top of [GetStorage](https://pub.dev/packages/get_storage) for fast local persistence.
* Abstract contracts (`IRelaxStorage`, `IEncrypter`) for testability and extensibility.
