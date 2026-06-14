enum TransactionStatus { pending, success, failed, cancelled, refunded }

enum WebhookEventType { paymentSuccess, paymentFailed, refundSuccess, unknown }

class WebhookEvent {
  final String transactionId;
  final WebhookEventType type;
  final Map<String, dynamic> rawData;

  WebhookEvent({
    required this.transactionId,
    required this.type,
    required this.rawData,
  });
}

class RetryConfig {
  final int maxAttempts;
  final int baseDelaySeconds;
  final Duration healthCheckInterval;

  const RetryConfig({
    this.maxAttempts = 3,
    this.baseDelaySeconds = 2,
    this.healthCheckInterval = const Duration(minutes: 5),
  });
}

class CustomerModel {
  final String email;
  final String? name;
  final String? phone;

  CustomerModel({required this.email, this.name, this.phone});
}

class PaymentRequest {
  final double amount;
  final String currency;
  final String transactionId;
  final CustomerModel? customer;
  final Map<String, dynamic> metadata;
  final String? idempotencyKey;

  PaymentRequest({
    required this.amount,
    required this.currency,
    required this.transactionId,
    this.customer,
    this.metadata = const {},
    this.idempotencyKey,
  });
}

class PaymentResponse {
  final String transactionId;
  final TransactionStatus status;
  final String? gatewayReference;
  final String? redirectUrl;
  final String? errorMessage;
  final Map<String, dynamic> rawResponse;

  PaymentResponse({
    required this.transactionId,
    required this.status,
    this.gatewayReference,
    this.redirectUrl,
    this.errorMessage,
    required this.rawResponse,
  });

  bool get isSuccess => status == TransactionStatus.success;
  bool get needsRedirect => redirectUrl != null;
}