import 'payment_provider.dart';
import 'payment_models.dart';
import 'payment_exceptions.dart';
import 'payment_logger.dart';

class StripeProvider implements PaymentProvider {
  @override
  String get name => 'stripe';

  late String _secretKey;
  late String _webhookSecret;

  @override
  Future<void> initialize(Map<String, String> config, {RelaxPayLogger? logger}) async {
    _secretKey = config['STRIPE_SECRET_KEY'] ?? '';
    _webhookSecret = config['STRIPE_WEBHOOK_SECRET'] ?? '';

    if (_secretKey.isEmpty) {
      throw ConfigurationException("STRIPE_SECRET_KEY is missing.");
    }
  }

  @override
  Future<PaymentResponse> pay(PaymentRequest request) async {
    try {
      // Simulating a Stripe API call to create a PaymentIntent
      // Note: idempotencyKey would be passed in the HTTP request headers
      // headers: {'Idempotency-Key': request.idempotencyKey ?? request.transactionId}
      
      final mockStripeId = "pi_${DateTime.now().millisecondsSinceEpoch}";
      
      return PaymentResponse(
        transactionId: request.transactionId,
        status: TransactionStatus.pending,
        gatewayReference: mockStripeId,
        rawResponse: {'id': mockStripeId, 'client_secret': 'sec_xxx'},
      );
    } catch (e) {
      throw ProviderException(e.toString(), name);
    }
  }

  @override
  Future<bool> verify(String transactionId) async {
    // Verification logic via Stripe API
    return true;
  }

  @override
  Future<bool> checkHealth() async {
    // Simulating a lightweight call to the Stripe API
    return true;
  }

  @override
  Future<PaymentResponse> refund(String transactionId, double amount) async {
    throw UnimplementedError("Refund non implémenté pour Stripe");
  }

  @override
  Future<WebhookEvent> handleWebhook(Map<String, dynamic> payload, Map<String, String> headers) async {
    final signature = headers['stripe-signature'];
    
    if (_webhookSecret.isNotEmpty) {
      if (signature == null || signature.isEmpty) {
        throw ProviderException("Webhook Validation: Missing signature", name);
      }
      // Here, the actual HMAC-SHA256 verification would be implemented
    }
    
    final eventType = payload['type'] as String;
    final dataObject = payload['data']['object'] as Map<String, dynamic>;
    
    WebhookEventType unifiedType;
    switch (eventType) {
      case 'payment_intent.succeeded':
        unifiedType = WebhookEventType.paymentSuccess;
        break;
      default:
        unifiedType = WebhookEventType.unknown;
    }

    return WebhookEvent(
      transactionId: dataObject['id'] ?? '',
      type: unifiedType,
      rawData: payload,
    );
  }
}