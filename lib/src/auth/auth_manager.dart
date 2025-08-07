import '../../netguard.dart';
import 'auth_interceptor.dart';

/// Authentication manager for NetGuard
class AuthManager {
  AuthInterceptor? _authInterceptor;
  AuthCallbacks? _callbacks;
  AuthConfig? _config;

  /// Check if authentication is configured
  bool get isConfigured => _authInterceptor != null;

  /// Get current auth interceptor
  AuthInterceptor? get interceptor => _authInterceptor;

  /// Get callbacks (for external access)
  AuthCallbacks? get callbacks => _callbacks;

  /// Get config (for external access)
  AuthConfig? get config => _config;

  /// Configure authentication with callbacks and config
  void configure({
    required AuthCallbacks callbacks,
    AuthConfig config = const AuthConfig(),
  }) {
    // FIXED: Store the references correctly (was overwriting with local variables)
    _callbacks = callbacks;
    _config = config;

    // Create the auth interceptor with the stored references
    _authInterceptor = AuthInterceptor(
      callbacks: _callbacks!,
      config: _config!,
    );

    print('🔐 AuthManager configured with:');
    print('   - Token Header: ${_config!.tokenHeaderName}');
    print('   - Token Prefix: "${_config!.tokenPrefix}"');
    print('   - Max Retry Attempts: ${_config!.maxRetryAttempts}');
    print('   - Auto Refresh: ${_config!.autoRefresh}');
    print('   - Enable Logging: ${_config!.enableLogging}');
  }

  /// Update tokens in the callbacks (if using AdvanceAuthCallbacks)
  Future<void> updateTokens({String? accessToken, String? refreshToken}) async {
    if (_callbacks is AdvanceAuthCallbacks) {
      final advancedCallbacks = _callbacks as AdvanceAuthCallbacks;
      advancedCallbacks.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      print('🔄 Tokens updated in AuthManager');
    }
  }

  /// Clear authentication configuration
  void clear() {
    _authInterceptor?.clear();
    _authInterceptor = null;
    _callbacks = null;
    _config = null;
    print('🗑️ AuthManager cleared');
  }

  /// Get authentication status for debugging
  Map<String, dynamic> getStatus() {
    if (!isConfigured) {
      return {'configured': false};
    }

    return {
      'configured': true,
      'isRefreshing': _authInterceptor!.isRefreshing,
      'queuedRequests': _authInterceptor!.queuedRequestsCount,
      'config': {
        'tokenHeaderName': _config!.tokenHeaderName,
        'tokenPrefix': _config!.tokenPrefix,
        'maxRetryAttempts': _config!.maxRetryAttempts,
        'autoRefresh': _config!.autoRefresh,
        'enableLogging': _config!.enableLogging,
      },
    };
  }

  /// Test token refresh manually (for debugging)
  Future<String?> testTokenRefresh() async {
    if (!isConfigured || _callbacks == null) {
      print('❌ AuthManager not configured for token refresh test');
      return null;
    }

    try {
      print('🧪 Testing token refresh...');
      final newToken = await _callbacks!.refreshToken();
      if (newToken != null) {
        print('✅ Token refresh test successful: ${newToken.substring(0, 20)}...');
        await _callbacks!.onTokenRefreshed(newToken);
        return newToken;
      } else {
        print('❌ Token refresh test returned null');
        return null;
      }
    } catch (e) {
      print('❌ Token refresh test failed: $e');
      return null;
    }
  }
}