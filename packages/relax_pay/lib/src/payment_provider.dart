import 'payment_models.dart';
import 'payment_logger.dart';

abstract class PaymentProvider {
  String get name;
  
  Future<void> initialize(Map<String, String> config, {RelaxPayLogger? logger});
  Future<PaymentResponse> pay(PaymentRequest request);
  Future<bool> verify(String transactionId);
  Future<PaymentResponse> refund(String transactionId, double amount);
  Future<WebhookEvent> handleWebhook(Map<String, dynamic> payload, Map<String, String> headers);
  Future<bool> checkHealth();
}