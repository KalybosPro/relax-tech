import 'package:envied/envied.dart';

part 'env.stg.g.dart';

@Envied(path: '.env.staging', obfuscate: true)
abstract class EnvStg {
  /// The value for App Name.
  @EnviedField(varName: 'APP_NAME', obfuscate: true)
  static final String appName = _EnvStg.appName;
  /// The value for App Suffix.
  @EnviedField(varName: 'APP_SUFFIX', obfuscate: true)
  static final String appSuffix = _EnvStg.appSuffix;
  /// The value for Base Url.
  @EnviedField(varName: 'BASE_URL', obfuscate: true)
  static final String baseUrl = _EnvStg.baseUrl;
  /// The value for Encryption Key.
  @EnviedField(varName: 'ENCRYPTION_KEY', obfuscate: true)
  static final String encryptionKey = _EnvStg.encryptionKey;

}
