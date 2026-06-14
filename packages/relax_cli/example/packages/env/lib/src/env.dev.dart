import 'package:envied/envied.dart';

part 'env.dev.g.dart';

@Envied(path: '.env.development', obfuscate: true)
abstract class EnvDev {
  /// The value for App Name.
  @EnviedField(varName: 'APP_NAME', obfuscate: true)
  static final String appName = _EnvDev.appName;
  /// The value for App Suffix.
  @EnviedField(varName: 'APP_SUFFIX', obfuscate: true)
  static final String appSuffix = _EnvDev.appSuffix;
  /// The value for Base Url.
  @EnviedField(varName: 'BASE_URL', obfuscate: true)
  static final String baseUrl = _EnvDev.baseUrl;
  /// The value for Encryption Key.
  @EnviedField(varName: 'ENCRYPTION_KEY', obfuscate: true)
  static final String encryptionKey = _EnvDev.encryptionKey;

}
