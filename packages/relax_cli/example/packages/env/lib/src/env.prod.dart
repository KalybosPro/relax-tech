import 'package:envied/envied.dart';

part 'env.prod.g.dart';

@Envied(path: '.env.production', obfuscate: true)
abstract class EnvProd {
  /// The value for App Name.
  @EnviedField(varName: 'APP_NAME', obfuscate: true)
  static final String appName = _EnvProd.appName;
  /// The value for App Suffix.
  @EnviedField(varName: 'APP_SUFFIX', obfuscate: true)
  static final String appSuffix = _EnvProd.appSuffix;
  /// The value for Base Url.
  @EnviedField(varName: 'BASE_URL', obfuscate: true)
  static final String baseUrl = _EnvProd.baseUrl;
  /// The value for Encryption Key.
  @EnviedField(varName: 'ENCRYPTION_KEY', obfuscate: true)
  static final String encryptionKey = _EnvProd.encryptionKey;

}
