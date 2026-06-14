import 'payment_provider.dart';
import 'payment_exceptions.dart';
import 'stripe_provider.dart';
import 'cinetpay_provider.dart';

class ProviderFactory {
  static final Map<String, PaymentProvider Function()> _registry = {
    'stripe': () => StripeProvider(),
    'cinetpay': () => CinetPayProvider(),
  };

  static void register(String name, PaymentProvider Function() factory) {
    _registry[name.toLowerCase()] = factory;
  }

  static PaymentProvider create(String providerName) {
    final factory = _registry[providerName.toLowerCase()];
    if (factory == null) {
      throw ConfigurationException("Provider '$providerName' is not registered or supported.");
    }
    return factory();
  }
}