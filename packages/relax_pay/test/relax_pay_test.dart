import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:relax_pay/relax_pay.dart';
import 'package:relax_pay/src/payment_provider.dart';
import 'package:relax_pay/src/provider_factory.dart';
import 'package:relax_pay/src/payment_logger.dart';

class MockProvider extends Mock implements PaymentProvider {}

class PaymentRequestFake extends Fake implements PaymentRequest {}

class MockRelaxPayLogger extends Mock implements RelaxPayLogger {}

void main() {
  late MockProvider primaryProvider;
  late MockProvider backupProvider;

  setUpAll(() {
    registerFallbackValue(PaymentRequestFake());
    registerFallbackValue(<String, String>{});
    registerFallbackValue(MockRelaxPayLogger());
  });

  setUp(() {
    primaryProvider = MockProvider();
    backupProvider = MockProvider();

    when(() => primaryProvider.name).thenReturn('stripe');
    when(() => backupProvider.name).thenReturn('cinetpay');
    
    // Manual registration of mocks in the factory for testing
    ProviderFactory.register('stripe', () => primaryProvider);
    ProviderFactory.register('cinetpay', () => backupProvider);
  });

  test('Should switch to backup if the primary provider fails', () async {
    // Configuration
    final config = {
      'PAYMENT_PROVIDER': 'stripe',
      'PAYMENT_PROVIDER_BACKUP': 'cinetpay',
    };

    final request = PaymentRequest(
      amount: 100,
      currency: 'XOF',
      transactionId: 'TEST-123',
    );

    // Simulating failure on the first and success on the second
    when(() => primaryProvider.initialize(any(), logger: any(named: 'logger')))
        .thenAnswer((_) async {});
    when(() => backupProvider.initialize(any(), logger: any(named: 'logger')))
        .thenAnswer((_) async {});
        
    when(() => primaryProvider.pay(request))
        .thenThrow(Exception("Stripe API Down"));
        
    when(() => backupProvider.pay(request)).thenAnswer((_) async => PaymentResponse(
          transactionId: 'TEST-123',
          status: TransactionStatus.success,
          rawResponse: {'status': 'ok'},
        ));

    // Execution
    await RelaxPay.instance.initialize(config);
    final response = await RelaxPay.instance.pay(request);

    // Verification
    expect(response.status, TransactionStatus.success);
    verify(() => primaryProvider.pay(request)).called(1);
    verify(() => backupProvider.pay(request)).called(1);
  });
}