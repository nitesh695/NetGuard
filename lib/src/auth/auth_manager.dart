import 'auth_interceptor.dart';

/// Authentication manager for NetGuard
class AuthManager {
  AuthInterceptor? authInterceptor;
  AuthCallbacks? callbacks;
  AuthConfig? config;

  /// Check if authentication is configured
  bool get isConfigured => authInterceptor != null;

  /// Get current auth interceptor
  AuthInterceptor? get interceptor => authInterceptor;

  /// Configure authentication with callbacks and config
  void configure({
    required AuthCallbacks callbacks,
    AuthConfig config = const AuthConfig(),
  }) {
    callbacks = callbacks;
    config = config;
    authInterceptor = AuthInterceptor(
      callbacks: callbacks,
      config: config,
    );
  }

  /// Clear authentication configuration
  void clear() {
    authInterceptor?.clear();
    authInterceptor = null;
    callbacks = null;
    config = null;
  }

  /// Get authentication status for debugging
  Map<String, dynamic> getStatus() {
    if (!isConfigured) {
      return {'configured': false};
    }

    return {
      'configured': true,
      'isRefreshing': authInterceptor!.isRefreshing,
      'queuedRequests': authInterceptor!.queuedRequestsCount,
      'config': {
        'tokenHeaderName': config!.tokenHeaderName,
        'tokenPrefix': config!.tokenPrefix,
        'maxRetryAttempts': config!.maxRetryAttempts,
        'autoRefresh': config!.autoRefresh,
        'enableLogging': config!.enableLogging,
      },
    };
  }
}