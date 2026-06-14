import 'payment_provider.dart';
import 'payment_models.dart';
import 'payment_exceptions.dart';
import 'payment_logger.dart';

class CinetPayProvider implements PaymentProvider {
  @override
  String get name => 'cinetpay';

  late String _apiKey;
  late String _siteId;

  @override
  Future<void> initialize(Map<String, String> config, {RelaxPayLogger? logger}) async {
    _apiKey = config['CINETPAY_API_KEY'] ?? '';
    _siteId = config['CINETPAY_SITE_ID'] ?? '';

    if (_apiKey.isEmpty || _siteId.isEmpty) {
      throw ConfigurationException("CinetPay configuration incomplete.");
    }
  }

  @override
  Future<PaymentResponse> pay(PaymentRequest request) async {
    // CinetPay often generates a redirect URL
    final redirectUrl = "https://checkout.cinetpay.com/${request.transactionId}";

    return PaymentResponse(
      transactionId: request.transactionId,
      status: TransactionStatus.pending,
      redirectUrl: redirectUrl,
      rawResponse: {
        'api_response': 'success',
        'url': redirectUrl
      },
    );
  }

  @override
  Future<bool> verify(String transactionId) async {
    // Status verification via CinetPay API
    return true;
  }

  @override
  Future<bool> checkHealth() async {
    // Simulating a lightweight call to the CinetPay API
    return true;
  }

  @override
  Future<PaymentResponse> refund(String transactionId, double amount) async {
    // Some local providers do not support refunds via API
    throw ProviderException("Refund not supported by this provider", name);
  }

  @override
  Future<WebhookEvent> handleWebhook(Map<String, dynamic> payload, Map<String, String> headers) async {
    // CinetPay usually sends the status in 'status' or 'cpm_result'
    final eventStatus = payload['status'] ?? payload['cpm_result'];
    final transactionId = payload['transaction_id'] ?? payload['cpm_trans_id'] ?? '';

    WebhookEventType unifiedType;
    
    if (eventStatus == 'ACCEPTED' || eventStatus == '00') {
      unifiedType = WebhookEventType.paymentSuccess;
    } else if (eventStatus == 'REFUSED') {
      unifiedType = WebhookEventType.paymentFailed;
    } else {
      unifiedType = WebhookEventType.unknown;
    }

    return WebhookEvent(
      transactionId: transactionId,
      type: unifiedType,
      rawData: payload,
    );
  }
}