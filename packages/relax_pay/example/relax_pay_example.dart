import 'package:relax_pay/relax_pay.dart';

void main() async {
  // 1. Simulation of an environment configuration (normally loaded via dotenv)
  final config = {
    'PAYMENT_PROVIDER': 'stripe',
    'PAYMENT_PROVIDER_BACKUP': 'cinetpay',
    'STRIPE_PUBLIC_KEY': 'pk_test_123456789',
    'STRIPE_SECRET_KEY': 'sk_test_123456789',
    'STRIPE_WEBHOOK_SECRET': 'whsec_test_secret',
    'CINETPAY_API_KEY': 'abc_123_xyz',
    'CINETPAY_SITE_ID': 'site_789',
  };

  // 2. Accessing the singleton instance and initializing
  final relaxPay = RelaxPay.instance;

  print('--- Initializing RelaxPay SDK ---');
  await relaxPay.initialize(
    config,
    retryConfig: const RetryConfig(
      maxAttempts: 3,
      baseDelaySeconds: 1,
      healthCheckInterval: Duration(seconds: 30),
    ),
  );

  print('SDK initialized with active provider: ${relaxPay.activeProviderName}');

  // 3. Listening to the webhook stream (Real-time reactivity)
  // Ideal for updating UI or triggering backend actions in a Flutter app
  relaxPay.onWebhookEvent.listen((event) {
    print('\n[WEBHOOK] Event received!');
    print(' - Transaction ID : ${event.transactionId}');
    print(' - Event type : ${event.type}');
    print(' - Raw data : ${event.rawData}');
  });

  // 4. Preparing a payment request
  final paymentRequest = PaymentRequest(
    amount: 2500.0,
    currency: 'XOF',
    transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
    customer: CustomerModel(
      email: 'client@example.com',
      name: 'John Doe',
      phone: '+2250102030405',
    ),
    metadata: {'order_id': 'CART_888'},
    idempotencyKey: 'unique_key_for_this_request_123',
  );

  // 5. Executing the payment
  print('\n--- Attempting to pay 2500 XOF ---');
  try {
    final response = await relaxPay.pay(paymentRequest);

    if (response.isSuccess) {
      print('✅ Payment successful! Gateway reference: ${response.gatewayReference}');
    } else if (response.needsRedirect) {
      print('🔗 Redirect necessary to: ${response.redirectUrl}');
      print('Current status: ${response.status}');
    } else {
      print('⚠️ Payment status: ${response.status}');
    }
  } catch (e) {
    print('❌ Error during payment: $e');
  }

  // 6. Simulating an incoming webhook (for demonstration of the reactive flow)
  print('\n--- Simulating an incoming webhook (Stripe) ---');
  await relaxPay.handleWebhook(
    {
      'type': 'payment_intent.succeeded',
      'data': {
        'object': {'id': 'pi_3MwaL2Lkdltvj5931UZfBR9G'}
      }
    },
    {'stripe-signature': 'mock_signature_data'},
  );
}