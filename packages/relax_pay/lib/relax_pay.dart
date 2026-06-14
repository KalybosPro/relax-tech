library;

import 'dart:async';
import 'dart:math' as math;
import 'src/payment_provider.dart';
import 'src/provider_factory.dart';
import 'src/payment_exceptions.dart';
import 'src/payment_models.dart';
import 'src/payment_logger.dart';

export 'src/payment_models.dart';
export 'src/payment_exceptions.dart';

/// The main facade of RelaxPay.
class RelaxPay {
  static final RelaxPay _instance = RelaxPay._internal();
  static RelaxPay get instance => _instance;

  RelaxPay._internal();

  late PaymentProvider _activeProvider;
  late PaymentProvider _primaryProvider;
  PaymentProvider? _backupProvider;
  RelaxPayLogger _logger = DefaultRelaxPayLogger();
  bool _isInitialized = false;
  RetryConfig _retryConfig = const RetryConfig();
  Timer? _healthCheckTimer;

  /// Stream to listen to webhook events.
  final StreamController<WebhookEvent> _webhookStreamController =
      StreamController<WebhookEvent>.broadcast();

  /// Exposes the event stream for UI or business services.
  Stream<WebhookEvent> get onWebhookEvent => _webhookStreamController.stream;

  String get activeProviderName => _activeProvider.name;

  /// Initializes the SDK with environment configurations.
  /// An optional custom [logger] can be provided.
  Future<void> initialize(
    Map<String, String> config, {
    RelaxPayLogger? logger,
    RetryConfig? retryConfig,
  }) async {
    if (_isInitialized) {
      _logger.info("RelaxPay is already initialized. Re-configuring...");
    }

    _stopHealthCheck();
    _backupProvider = null; // Resetting the backup to avoid configuration leaks

    if (retryConfig != null) _retryConfig = retryConfig;

    if (logger != null) _logger = logger;

    final providerName = config['PAYMENT_PROVIDER'];
    if (providerName == null)
      throw ConfigurationException("PAYMENT_PROVIDER not defined");

    _logger.info("Initializing RelaxPay with provider: $providerName");

    _activeProvider = ProviderFactory.create(providerName);
    _primaryProvider = _activeProvider;
    await _activeProvider.initialize(config, logger: _logger);

    // Optional backup initialization
    final backupName = config['PAYMENT_PROVIDER_BACKUP'];
    if (backupName != null && backupName != providerName) {
      try {
        _backupProvider = ProviderFactory.create(backupName);
        await _backupProvider!.initialize(config, logger: _logger);
      } catch (e) {
        _logger.warning("The backup provider failed to initialize", e);
      }
    }

    _isInitialized = true;
  }

  /// Unique entry point to initiate a payment.
  Future<PaymentResponse> pay(PaymentRequest request) async {
    _ensureInitialized();
    return _withRetry(() async {
      try {
        return await _activeProvider.pay(request);
      } catch (e) {
        if (_backupProvider != null) {
          return await _handleFailover(request, e);
        }
        rethrow;
      }
    });
  }

  /// Processes an incoming webhook and returns a unified event.
  /// Useful for Dart servers (Shelf, Dart Frog) or Cloud Functions.
  Future<WebhookEvent> handleWebhook(
    Map<String, dynamic> payload,
    Map<String, String> headers,
  ) async {
    _ensureInitialized();
    final event = await _activeProvider.handleWebhook(payload, headers);
    _webhookStreamController.add(event);
    return event;
  }

  /// Verifies the status of a transaction.
  Future<bool> verify(String transactionId) async {
    _ensureInitialized();
    return await _activeProvider.verify(transactionId);
  }

  /// Automatic Failover strategy.
  Future<PaymentResponse> _handleFailover(
    PaymentRequest request,
    dynamic error,
  ) async {
    if (_activeProvider != _primaryProvider) {
      return await _activeProvider.pay(request);
    }

    _logger.error(
      "Primary provider ${_primaryProvider.name} failed. Switching to backup...",
      error,
    );

    _activeProvider = _backupProvider!;
    _startHealthCheck();

    try {
      return await _backupProvider!.pay(request);
    } catch (failoverError) {
      _logger.error(
        "Failover to ${_activeProvider.name} also failed.",
        failoverError,
      );
      throw ProviderException(
        "Primary and backup providers failed.",
        "FAILOVER_SYSTEM",
      );
    }
  }

  /// Exponential retry logic for transient errors.
  Future<T> _withRetry<T>(Future<T> Function() action) async {
    for (int i = 0; i < _retryConfig.maxAttempts; i++) {
      try {
        return await action();
      } on ConfigurationException {
        rethrow; // Do not retry if the configuration is invalid
      } on UnimplementedError {
        rethrow; // Do not retry if the functionality is not implemented
      } catch (e) {
        if (i == _retryConfig.maxAttempts - 1) rethrow;

        final delay = math.pow(_retryConfig.baseDelaySeconds, i).toInt();
        _logger.warning("Attempt ${i + 1} failed, retrying in ${delay}s...");
        await Future.delayed(Duration(seconds: delay), action);
      }
    }
    throw ProviderException(
      "Failed after multiple attempts",
      activeProviderName,
    );
  }

  void _startHealthCheck() {
    if (_healthCheckTimer != null) return;

    _logger.info("Starting Health Check for ${_primaryProvider.name}...");
    _healthCheckTimer = Timer.periodic(_retryConfig.healthCheckInterval, (
      timer,
    ) async {
      try {
        final isHealthy = await _primaryProvider.checkHealth();
        if (isHealthy) {
          _logger.info(
            "The provider ${_primaryProvider.name} is healthy again. Returning to primary provider.",
          );
          _activeProvider = _primaryProvider;
          _stopHealthCheck();
        }
      } catch (e) {
        _logger.warning("Health Check failed for ${_primaryProvider.name}");
      }
    });
  }

  void _stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw InitializationException("RelaxPay must be initialized before use.");
    }
  }

  void dispose() {
    _stopHealthCheck();
    _webhookStreamController.close();
  }
}
