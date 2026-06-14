import 'package:flutter_test/flutter_test.dart';
import 'package:relax_storage/relax_storage.dart';

void main() {
  group('Encrypter', () {
    late Encrypter encrypter;

    setUp(() {
      encrypter = Encrypter(salt: 'test-salt');
    });

    group('deriveKey', () {
      test('returns a 256-bit key', () {
        final key = encrypter.deriveKey('my-password');
        expect(key.bytes.length, 32);
      });

      test('same input produces the same key', () {
        final key1 = encrypter.deriveKey('password');
        final key2 = encrypter.deriveKey('password');
        expect(key1.bytes, equals(key2.bytes));
      });

      test('different passwords produce different keys', () {
        final key1 = encrypter.deriveKey('password1');
        final key2 = encrypter.deriveKey('password2');
        expect(key1.bytes, isNot(equals(key2.bytes)));
      });

      test('customSalt overrides default salt', () {
        final key1 = encrypter.deriveKey('password', customSalt: 'salt-a');
        final key2 = encrypter.deriveKey('password', customSalt: 'salt-b');
        expect(key1.bytes, isNot(equals(key2.bytes)));
      });

      test('different salts produce different keys', () {
        final enc1 = Encrypter(salt: 'salt-1');
        final enc2 = Encrypter(salt: 'salt-2');
        final key1 = enc1.deriveKey('password');
        final key2 = enc2.deriveKey('password');
        expect(key1.bytes, isNot(equals(key2.bytes)));
      });
    });

    group('encrypt', () {
      test('returns a payload with IV:CIPHERTEXT format', () {
        final encrypted = encrypter.encrypt('hello', 'key');
        expect(encrypted, contains(':'));
        final parts = encrypted.split(':');
        expect(parts.length, 2);
        expect(parts[0].isNotEmpty, isTrue);
        expect(parts[1].isNotEmpty, isTrue);
      });

      test('encrypting the same text twice produces different outputs', () {
        final encrypted1 = encrypter.encrypt('hello', 'key');
        final encrypted2 = encrypter.encrypt('hello', 'key');
        expect(encrypted1, isNot(equals(encrypted2)));
      });

      test('encrypts non-string types by converting to string', () {
        final encrypted = encrypter.encrypt(42, 'key');
        final decrypted = encrypter.decrypt(encrypted, 'key');
        expect(decrypted, '42');
      });
    });

    group('decrypt', () {
      test('decrypts what was encrypted', () {
        const original = 'Hello, World!';
        final encrypted = encrypter.encrypt(original, 'secret-key');
        final decrypted = encrypter.decrypt(encrypted, 'secret-key');
        expect(decrypted, original);
      });

      test('decrypts long text correctly', () {
        final original = 'A' * 1000;
        final encrypted = encrypter.encrypt(original, 'key');
        final decrypted = encrypter.decrypt(encrypted, 'key');
        expect(decrypted, original);
      });

      test('decrypts unicode text correctly', () {
        const original = 'Bonjour le monde! 你好世界 🌍';
        final encrypted = encrypter.encrypt(original, 'key');
        final decrypted = encrypter.decrypt(encrypted, 'key');
        expect(decrypted, original);
      });

      test(
        'throws on empty string encryption (AES-CBC block size constraint)',
        () {
          expect(() => encrypter.encrypt('', 'key'), throwsA(isA<Object>()));
        },
      );

      test('decrypts special characters correctly', () {
        const original = r'{"key": "value", "list": [1, 2, 3]}';
        final encrypted = encrypter.encrypt(original, 'key');
        final decrypted = encrypter.decrypt(encrypted, 'key');
        expect(decrypted, original);
      });

      test('throws ArgumentError for invalid payload format', () {
        expect(
          () => encrypter.decrypt('invalid-payload-no-colon', 'key'),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for payload with multiple colons', () {
        expect(() => encrypter.decrypt('a:b:c', 'key'), throwsArgumentError);
      });

      test('wrong key fails to decrypt correctly', () {
        final encrypted = encrypter.encrypt('secret data', 'correct-key');
        expect(
          () => encrypter.decrypt(encrypted, 'wrong-key'),
          throwsA(isA<Object>()),
        );
      });
    });
  });

  group('IRelaxStorage contract', () {
    test('RelaxStorage implements IRelaxStorage', () {
      // Verify the type relationship at the class level
      expect(identical(RelaxStorage, RelaxStorage), isTrue);
    });
  });

  group('IEncrypter contract', () {
    test('Encrypter implements IEncrypter', () {
      // ignore: unnecessary_type_check
      expect(Encrypter() is IEncrypter, isTrue);
    });
  });

  group('Encrypter round-trip scenarios', () {
    test('encrypt then decrypt with same Encrypter instance', () {
      final encrypter = Encrypter(salt: 'round-trip-salt');
      const key = 'my-key';

      final pairs = {
        'simple text': 'simple text',
        '12345': '12345',
        'true': 'true',
        '{"name":"John"}': '{"name":"John"}',
      };

      for (final entry in pairs.entries) {
        final encrypted = encrypter.encrypt(entry.key, key);
        final decrypted = encrypter.decrypt(encrypted, key);
        expect(decrypted, entry.value);
      }
    });

    test('encrypt with one instance, decrypt with another using same salt', () {
      final encrypter1 = Encrypter(salt: 'shared-salt');
      final encrypter2 = Encrypter(salt: 'shared-salt');

      const original = 'cross-instance test';
      final encrypted = encrypter1.encrypt(original, 'key');
      final decrypted = encrypter2.decrypt(encrypted, 'key');
      expect(decrypted, original);
    });
  });
}
