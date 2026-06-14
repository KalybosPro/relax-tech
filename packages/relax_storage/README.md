> [!IMPORTANT]
> ## 📦 This repository has moved
> `relax_storage` is now developed in the **[KalybosPro/relax-tech](https://github.com/KalybosPro/relax-tech)** monorepo, together with the rest of the Relax packages.
>
> - 👉 **Active source:** https://github.com/KalybosPro/relax-tech/tree/main/packages/relax_storage
> - 🐛 **Issues & Pull Requests:** please open them in the [monorepo](https://github.com/KalybosPro/relax-tech/issues) — this repo no longer tracks them.
> - 📥 **On pub.dev:** nothing changes. `dart pub add relax_storage` keeps working exactly as before.
>
> This repository is **archived** for historical reference and will not receive further updates.

---

<!-- ↓↓↓ Original README kept below for reference ↓↓↓ -->

# RelaxStorage

[![pub package](https://img.shields.io/pub/v/relax_storage.svg)](https://pub.dev/packages/relax_storage)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A secure Flutter storage package with **AES-CBC encryption**. All data is automatically encrypted before being persisted and decrypted when read back, using SHA-256 key derivation and random IV generation for each write.

Built on top of [GetStorage](https://pub.dev/packages/get_storage) for fast, lightweight local persistence.

## Features

- **AES-CBC Encryption** — All stored values are encrypted with AES-256 in CBC mode.
- **SHA-256 Key Derivation** — Encryption keys are derived from your passphrase using SHA-256 with a salt.
- **Random IV** — A unique random Initialization Vector is generated per write, so storing the same value twice produces different ciphertexts.
- **Type-safe** — Generic `save<T>` / `read<T>` API with built-in support for `String`, `int`, `double`, `bool`, and JSON-serializable types.
- **Simple API** — Four methods: `save`, `read`, `delete`, `clear`.
- **Extensible** — Abstract contracts (`IRelaxStorage`, `IEncrypter`) allow you to swap implementations for testing or custom backends.

## Getting Started

### Installation

Add `relax_storage` to your `pubspec.yaml`:

```yaml
dependencies:
  relax_storage: ^1.0.1
```

Then run:

```bash
flutter pub get
```

### Initialization

Call `RelaxStorage.init()` once before using the storage, typically in your `main()` function:

```dart
import 'package:flutter/material.dart';
import 'package:relax_storage/relax_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RelaxStorage.init();
  runApp(const MyApp());
}
```

## Usage

### Basic CRUD Operations

```dart
// Create an instance with your encryption key
final storage = RelaxStorage('my-secret-key');

// Save data
await storage.save<String>('token', 'eyJhbGciOiJIUzI1NiIs...');
await storage.save<int>('loginCount', 5);
await storage.save<double>('rating', 4.8);
await storage.save<bool>('isPremium', true);

// Read data
final token = storage.read<String>('token');       // 'eyJhbGciOiJIUzI1NiIs...'
final count = storage.read<int>('loginCount');      // 5
final rating = storage.read<double>('rating');      // 4.8
final premium = storage.read<bool>('isPremium');    // true

// Read a missing key returns null
final missing = storage.read<String>('nonexistent'); // null

// Delete a single key
await storage.delete('token');

// Clear all stored data
await storage.clear();
```

### Using the Encrypter Directly

If you only need encryption without storage:

```dart
final encrypter = Encrypter(salt: 'my-salt');

// Encrypt
final encrypted = encrypter.encrypt('sensitive data', 'my-key');
print(encrypted); // e.g. "aGVsbG8=:Y2lwaGVy..."

// Decrypt
final decrypted = encrypter.decrypt(encrypted, 'my-key');
print(decrypted); // 'sensitive data'
```

### Custom Encryption

Implement `IEncrypter` to provide your own encryption strategy:

```dart
class MyCustomEncrypter implements IEncrypter {
  @override
  Key deriveKey(String key, {String? customSalt}) {
    // Your custom key derivation
  }

  @override
  String encrypt<T>(T data, String key) {
    // Your custom encryption
  }

  @override
  String decrypt(String encryptedText, String key) {
    // Your custom decryption
  }
}
```

## API Reference

### RelaxStorage

| Method | Description |
|--------|-------------|
| `RelaxStorage([String? encryptionKey])` | Creates an instance with an optional encryption key. |
| `static Future<bool> init()` | Initializes the storage engine. Call once at app startup. |
| `Future<void> save<T>(String key, T data)` | Encrypts and stores a value. |
| `T? read<T>(String key)` | Reads and decrypts a value. Returns `null` if not found. |
| `Future<void> delete(String key)` | Removes a stored value. |
| `Future<void> clear()` | Removes all stored values. |

### Encrypter

| Method | Description |
|--------|-------------|
| `Encrypter({String salt})` | Creates an encrypter with a custom salt. |
| `Key deriveKey(String key, {String? customSalt})` | Derives a 256-bit AES key from a password. |
| `String encrypt<T>(T data, String key)` | Encrypts data and returns `"IV:CIPHERTEXT"` in Base64. |
| `String decrypt(String payload, String key)` | Decrypts a payload produced by `encrypt`. |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
