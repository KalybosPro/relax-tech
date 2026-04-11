// ignore_for_file: avoid_print

import 'package:env_builder_cli/src/core/core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('assets_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CodeGenerator', () {
    group('generateFileExporter', () {
      test('should generate correct export for default suffix', () {
        // Act
        final result = CodeGenerator.generateFileExporter('');

        // Assert
        expect(result, equals("export 'src/env.dart';"));
      });

      test('should generate correct export for specific suffix', () {
        // Act
        final result = CodeGenerator.generateFileExporter('prod');

        // Assert
        expect(result, equals("export 'src/env.prod.dart';"));
      });

      test('should generate correct export for dev suffix', () {
        // Act
        final result = CodeGenerator.generateFileExporter('dev');

        // Assert
        expect(result, equals("export 'src/env.dev.dart';"));
      });
    });

    group('generateEnvClassContent', () {
      test('should generate valid Dart class for env file', () async {
        // Arrange
        const envContent = 'API_KEY=test_key\nDATABASE_URL=localhost';
        final envFile = File(p.join(tempDir.path, '.env.prod'));
        await envFile.writeAsString(envContent);

        // Act
        final result = CodeGenerator.generateEnvClassContent(
          '.env.prod',
          'EnvProd',
          envFile,
        );

        // Assert
        expect(result, contains('import \'package:envied/envied.dart\';'),
            reason: 'Should import envied package');
        expect(result, contains('abstract class EnvProd'),
            reason: 'Should define EnvProd class');
        expect(result, contains('@Envied('),
            reason: 'Should have @Envied annotation');
        expect(result, contains('static final String apiKey'),
            reason: 'Should have API_KEY field as apiKey');
        expect(result, contains('static final String databaseUrl'),
            reason: 'Should have DATABASE_URL field as databaseUrl');
      });

      test('should handle special characters in keys', () async {
        // Arrange
        const envContent = 'API_KEY_V2=value\nDB_HOST_NAME=localhost';
        final envFile = File(p.join(tempDir.path, '.env.special'));
        await envFile.writeAsString(envContent);

        // Act
        final result = CodeGenerator.generateEnvClassContent(
          '.env.special',
          'EnvSpecial',
          envFile,
        );

        // Assert
        expect(result, contains('apiKeyV2'),
            reason: 'Should convert API_KEY_V2 to apiKeyV2');
        expect(result, contains('dbHostName'),
            reason: 'Should convert DB_HOST_NAME to dbHostName');
      });

      test('should generate obfuscate flag', () async {
        // Arrange
        const envContent = 'SECRET_KEY=hidden';
        final envFile = File(p.join(tempDir.path, '.env.secret'));
        await envFile.writeAsString(envContent);

        // Act
        final result = CodeGenerator.generateEnvClassContent(
          '.env.secret',
          'EnvSecret',
          envFile,
        );

        // Assert
        expect(result, contains('obfuscate: true'),
            reason: 'Should have obfuscate flag set to true');
      });

      test('should handle empty env file', () async {
        // Arrange
        final envFile = File(p.join(tempDir.path, '.env.prod'));
        await envFile.writeAsString('');

        // Act
        final result = CodeGenerator.generateEnvClassContent(
          '.env.prod',
          'EnvProd',
          envFile,
        );

        // Assert
        expect(result, contains('abstract class EnvProd'),
            reason: 'Should create class even for empty file');
      });

      test('should handle multiline env content', () async {
        // Arrange
        const envContent = '''API_KEY=abc123
DATABASE_URL=postgres://localhost
CACHE_ENABLED=true
DEBUG_LEVEL=verbose
TIMEOUT_SECONDS=30''';
        final envFile = File(p.join(tempDir.path, '.env.multi'));
        await envFile.writeAsString(envContent);

        // Act
        final result = CodeGenerator.generateEnvClassContent(
          '.env.multi',
          'EnvMulti',
          envFile,
        );

        // Assert
        expect(result, contains('apiKey'),
            reason: 'Should have first variable');
        expect(result, contains('databaseUrl'),
            reason: 'Should have second variable');
        expect(result, contains('cacheEnabled'),
            reason: 'Should have third variable');
        expect(result, contains('debugLevel'),
            reason: 'Should have fourth variable');
        expect(result, contains('timeoutSeconds'),
            reason: 'Should have fifth variable');
      });
    });
  });

  group('EnvFileParser', () {
    group('parseEnvFile', () {
      test('should parse basic env file', () async {
        // Arrange
        const envContent = 'API_KEY=secret123\nDB_PORT=5432';
        final envFile = File(p.join(tempDir.path, '.env'));
        await envFile.writeAsString(envContent);

        // Act
        final result = EnvFileParser.parseEnvFile(envFile);

        // Assert
        expect(result['API_KEY'], equals('secret123'));
        expect(result['DB_PORT'], equals('5432'));
        expect(result.length, equals(2));
      });

      test('should ignore comment lines', () async {
        // Arrange
        const envContent = '''# This is a comment
API_KEY=secret123
# Another comment
DB_PORT=5432''';
        final envFile = File(p.join(tempDir.path, '.env.comments'));
        await envFile.writeAsString(envContent);

        // Act
        final result = EnvFileParser.parseEnvFile(envFile);

        // Assert
        expect(result.length, equals(2),
            reason: 'Should ignore comment lines');
        expect(result['API_KEY'], equals('secret123'));
      });

      test('should trim whitespace from keys and values', () async {
        // Arrange
        const envContent = '  API_KEY  =  secret123  \nDB_PORT = 5432 ';
        final envFile =
            File(p.join(tempDir.path, '.env.whitespace'));
        await envFile.writeAsString(envContent);

        // Act
        final result = EnvFileParser.parseEnvFile(envFile);

        // Assert
        expect(result['API_KEY'], equals('secret123'),
            reason: 'Should trim whitespace from values');
        expect(result['DB_PORT'], equals('5432'));
      });

      test('should handle quoted values', () async {
        // Arrange
        const envContent = '''API_KEY="secret123"
DB_PASSWORD='pass456'
NORMAL_VALUE=unquoted''';
        final envFile = File(p.join(tempDir.path, '.env.quoted'));
        await envFile.writeAsString(envContent);

        // Act
        final result = EnvFileParser.parseEnvFile(envFile);

        // Assert
        expect(result['API_KEY'], equals('secret123'),
            reason: 'Should remove double quotes');
        expect(result['DB_PASSWORD'], equals('pass456'),
            reason: 'Should remove single quotes');
        expect(result['NORMAL_VALUE'], equals('unquoted'));
      });

      test('should handle empty values', () async {
        // Arrange
        const envContent = 'EMPTY_VALUE=\nFILLED_VALUE=something';
        final envFile = File(p.join(tempDir.path, '.env.empty'));
        await envFile.writeAsString(envContent);

        // Act
        final result = EnvFileParser.parseEnvFile(envFile);

        // Assert
        expect(result['EMPTY_VALUE'], equals(''));
        expect(result['FILLED_VALUE'], equals('something'));
      });

      test('should skip lines without equals sign', () async {
        // Arrange
        const envContent = '''VALID_KEY=value
INVALID_LINE_NO_EQUALS
ANOTHER_VALID=test''';
        final envFile = File(p.join(tempDir.path, '.env.invalid'));
        await envFile.writeAsString(envContent);

        // Act
        final result = EnvFileParser.parseEnvFile(envFile);

        // Assert
        expect(result.length, equals(2),
            reason: 'Should skip lines without equals');
        expect(result.containsKey('INVALID_LINE_NO_EQUALS'), false);
      });

      test('should handle special characters in values', () async {
        // Arrange
        const envContent =
            'DATABASE_URL=postgres://user:p@ss!@localhost:5432/db\nAPI_KEY=sk!@#\$%^&*()';
        final envFile =
            File(p.join(tempDir.path, '.env.special'));
        await envFile.writeAsString(envContent);

        // Act
        final result = EnvFileParser.parseEnvFile(envFile);

        // Assert
        expect(result['DATABASE_URL'],
            equals('postgres://user:p@ss!@localhost:5432/db'));
        expect(result['API_KEY'], equals(r'sk!@#$%^&*()'));
      });

      test('should handle values with equals signs', () async {
        // Arrange
        const envContent = 'FORMULA=E=mc2\nJWT_TOKEN=header.payload.signature';
        final envFile = File(p.join(tempDir.path, '.env.equals'));
        await envFile.writeAsString(envContent);

        // Act
        final result = EnvFileParser.parseEnvFile(envFile);

        // Assert
        expect(result['FORMULA'], equals('E=mc2'),
            reason: 'Should handle equals in values');
        expect(result['JWT_TOKEN'], equals('header.payload.signature'));
      });

      test('should handle empty file', () async {
        // Arrange
        final envFile = File(p.join(tempDir.path, '.env.blank'));
        await envFile.writeAsString('');

        // Act
        final result = EnvFileParser.parseEnvFile(envFile);

        // Assert
        expect(result.isEmpty, true,
            reason: 'Empty file should return empty map');
      });

      test('should handle file with only comments', () async {
        // Arrange
        const envContent = '''# Comment 1
# Comment 2
# Comment 3''';
        final envFile = File(p.join(tempDir.path, '.env.onlycomments'));
        await envFile.writeAsString(envContent);

        // Act
        final result = EnvFileParser.parseEnvFile(envFile);

        // Assert
        expect(result.isEmpty, true,
            reason: 'File with only comments should return empty map');
      });
    });
  });

  group('NamingUtils', () {
    group('toCamelCase', () {
      test('should convert SCREAMING_SNAKE_CASE to camelCase', () {
        // Act
        final result = NamingUtils.toCamelCase('API_KEY');

        // Assert
        expect(result, equals('apiKey'));
      });

      test('should handle multiple underscores', () {
        // Act
        final result = NamingUtils.toCamelCase('DB_HOST_NAME_PROD');

        // Assert
        expect(result, equals('dbHostNameProd'));
      });

      test('should handle single word', () {
        // Act
        final result = NamingUtils.toCamelCase('KEY');

        // Assert
        expect(result, equals('key'));
      });

      test('should handle lowercase input', () {
        // Act
        final result = NamingUtils.toCamelCase('api_key');

        // Assert
        expect(result, equals('apiKey'));
      });

      test('should handle mixed case input', () {
        // Act
        final result = NamingUtils.toCamelCase('Api_Key_Test');

        // Assert
        expect(result, equals('apiKeyTest'));
      });
    });

    group('capitalizeFirst', () {
      test('should capitalize first letter', () {
        // Act
        final result = NamingUtils.capitalizeFirst('hello');

        // Assert
        expect(result, equals('Hello'));
      });

      test('should handle already capitalized string', () {
        // Act
        final result = NamingUtils.capitalizeFirst('Hello');

        // Assert
        expect(result, equals('Hello'));
      });

      test('should handle single character', () {
        // Act
        final result = NamingUtils.capitalizeFirst('a');

        // Assert
        expect(result, equals('A'));
      });
    });

    group('getEnvironmentClassName', () {
      test('should generate class name for .env file', () {
        // Act
        final result = NamingUtils.getEnvironmentClassName('.env');

        // Assert
        // .env defaults to production
        expect(result, equals('EnvProd'));
      });

      test('should generate class name for .env.development', () {
        // Act
        final result =
            NamingUtils.getEnvironmentClassName('.env.development');

        // Assert
        expect(result, equals('EnvDev'));
      });

      test('should generate class name for .env.production', () {
        // Act
        final result =
            NamingUtils.getEnvironmentClassName('.env.production');

        // Assert
        expect(result, equals('EnvProd'));
      });
    });

    group('getEnvironmentSuffix', () {
      test('should extract suffix from .env.development', () {
        // Act
        final result = NamingUtils.getEnvironmentSuffix('.env.development');

        // Assert
        expect(result, equals('dev'));
      });

      test('should return prod for .env', () {
        // Act
        final result = NamingUtils.getEnvironmentSuffix('.env');

        // Assert
        // .env defaults to production
        expect(result, equals('prod'));
      });

      test('should extract suffix from .env.production', () {
        // Act
        final result = NamingUtils.getEnvironmentSuffix('.env.production');

        // Assert
        expect(result, equals('prod'));
      });
    });

    group('getEnvironmentDartFileName', () {
      test('should generate dart filename for .env', () {
        // Act
        final result = NamingUtils.getEnvironmentDartFileName('.env');

        // Assert
        // .env defaults to production
        expect(result, equals('env.prod.dart'));
      });

      test('should generate dart filename for .env.development', () {
        // Act
        final result =
            NamingUtils.getEnvironmentDartFileName('.env.development');

        // Assert
        expect(result, equals('env.dev.dart'));
      });

      test('should generate dart filename for .env.production', () {
        // Act
        final result =
            NamingUtils.getEnvironmentDartFileName('.env.production');

        // Assert
        expect(result, equals('env.prod.dart'));
      });
    });
  });
}
