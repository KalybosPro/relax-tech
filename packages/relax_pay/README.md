# RelaxPay SDK

Agnostic Dart/Flutter SDK for multi-provider payment integration with automatic failover.

## Features

- **Total agnosticism** — Change providers via environment config without touching business code
- **Automatic failover** — Falls back to a backup provider on primary failure, restores primary via health checks
- **Unified models** — Single interface for Stripe, CinetPay, PayGate, and custom providers
- **Webhook standardizer** — Unified management of asynchronous payment notifications
- **Retry strategy** — Exponential backoff with configurable attempts and intervals
- **Extensible logging** — Provide your own `RelaxPayLogger` implementation

## Installation

```yaml
dependencies:
  relax_pay:
    path: ../relax_pay
```

## Configuration

Set environment variables (or pass a `Map<String, String>` directly):

```env
PAYMENT_PROVIDER=stripe
PAYMENT_PROVIDER_BACKUP=cinetpay

# Stripe
STRIPE_PUBLIC_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...

# CinetPay
CINETPAY_API_KEY=...
CINETPAY_SITE_ID=...
```

## Usage

### Initialize

```dart
import 'package:relax_pay/relax_pay.dart';

await RelaxPay.instance.initialize(dotenv.env);

// With optional custom logger and retry config
await RelaxPay.instance.initialize(
  dotenv.env,
  logger: MyLogger(),
  retryConfig: RetryConfig(
    maxAttempts: 3,
    baseDelaySeconds: 2,
    healthCheckInterval: Duration(minutes: 5),
  ),
);
```

### Initiate a payment

```dart
final response = await RelaxPay.instance.pay(
  PaymentRequest(
    amount: 5000,
    currency: 'XOF',
    transactionId: 'REF-12345',
    customer: CustomerModel(email: 'user@example.com'),
  ),
);

if (response.needsRedirect) {
  // Redirect to provider URL (e.g. Stripe Checkout, CinetPay)
  launchUrl(Uri.parse(response.redirectUrl!));
}
```

### Verify a transaction

```dart
final isValid = await RelaxPay.instance.verify('REF-12345');
```

### Handle a webhook

```dart
// On your server (Shelf, Dart Frog, Cloud Function)
final event = await RelaxPay.instance.handleWebhook(payload, headers);
```

### Listen to webhook events (client-side stream)

```dart
RelaxPay.instance.onWebhookEvent.listen((event) {
  if (event.type == WebhookEventType.paymentSuccess) {
    print('Transaction ${event.transactionId} confirmed.');
  }
});
```

### Clean up

```dart
RelaxPay.instance.dispose();
```

## Add a custom provider

Implement `PaymentProvider` and register it with `ProviderFactory`:

```dart
class MyCustomProvider implements PaymentProvider {
  @override
  String get name => 'my_provider';

  @override
  Future<void> initialize(Map<String, String> config, {RelaxPayLogger? logger}) async { ... }

  @override
  Future<PaymentResponse> pay(PaymentRequest request) async { ... }

  @override
  Future<WebhookEvent> handleWebhook(Map<String, dynamic> payload, Map<String, String> headers) async { ... }

  @override
  Future<bool> verify(String transactionId) async { ... }

  @override
  Future<bool> checkHealth() async { ... }
}

// Register before initialize()
ProviderFactory.register('my_provider', () => MyCustomProvider());
```

## API Reference

### RelaxPay

| Member | Description |
|--------|-------------|
| `RelaxPay.instance` | Singleton access |
| `initialize(config, {logger, retryConfig})` | Configure with env map. Safe to call again to re-configure. |
| `pay(PaymentRequest)` → `PaymentResponse` | Initiate a payment with automatic retry and failover |
| `verify(transactionId)` → `bool` | Verify a transaction status |
| `handleWebhook(payload, headers)` → `WebhookEvent` | Parse and normalize a webhook payload |
| `onWebhookEvent` | Broadcast stream of `WebhookEvent` objects |
| `activeProviderName` | Name of the currently active provider |
| `dispose()` | Cancel health-check timers and close the event stream |

### RetryConfig

| Parameter | Default | Description |
|-----------|---------|-------------|
| `maxAttempts` | `3` | Maximum number of retry attempts |
| `baseDelaySeconds` | `2` | Base delay for exponential backoff (seconds) |
| `healthCheckInterval` | `5 min` | How often to poll primary provider after failover |

### Exceptions

| Exception | Thrown when |
|-----------|-------------|
| `InitializationException` | Calling `pay`/`verify`/`handleWebhook` before `initialize` |
| `ConfigurationException` | `PAYMENT_PROVIDER` is missing or invalid |
| `ProviderException` | Both primary and backup providers fail |

## License

MIT
