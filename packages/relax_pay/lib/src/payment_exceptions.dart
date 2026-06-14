abstract class RelaxPayException implements Exception {
  final String message;
  final String? code;

  RelaxPayException(this.message, [this.code]);

  @override
  String toString() => 'RelaxPayException: [$code] $message';
}

class ConfigurationException extends RelaxPayException {
  ConfigurationException(String message) : super(message, 'CONFIG_ERROR');
}

class ProviderException extends RelaxPayException {
  ProviderException(String message, String provider) : super(message, 'PROVIDER_ERROR_$provider');
}

class InitializationException extends RelaxPayException {
  InitializationException(String message) : super(message, 'INITIALIZATION_ERROR');
}