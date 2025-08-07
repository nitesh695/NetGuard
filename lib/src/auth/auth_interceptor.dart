import 'dart:async';
import 'package:dio/dio.dart';

/// Configuration for authentication behavior
class AuthConfig {
  /// Custom header name for the token (default: 'Authorization')
  final String tokenHeaderName;

  /// Token prefix (e.g., 'Bearer ', 'Token ', or empty string)
  final String tokenPrefix;

  /// Maximum number of retry attempts for token refresh
  final int maxRetryAttempts;

  /// Delay between retry attempts
  final Duration retryDelay;

  /// Whether to automatically refresh tokens on 401 responses
  final bool autoRefresh;

  /// Whether to log authentication activities (for debugging)
  final bool enableLogging;

  const AuthConfig({
    this.tokenHeaderName = 'Authorization',
    this.tokenPrefix = 'Bearer ',
    this.maxRetryAttempts = 1,
    this.retryDelay = const Duration(milliseconds: 500),
    this.autoRefresh = true,
    this.enableLogging = false,
  });
}

/// Authentication callbacks interface
abstract class AuthCallbacks {
  /// Get current stored token
  Future<String?> getToken();

  /// Refresh the current token
  Future<String?> refreshToken();

  /// Called when a new token is obtained through refresh
  Future<void> onTokenRefreshed(String newToken);

  /// Called when authentication fails and user should be logged out
  Future<void> onLogout();
}

/// Internal class to hold pending auth request information
class _PendingAuthRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;
  final Completer<Response> completer;
  final DateTime timestamp;

  _PendingAuthRequest(this.options, this.handler, this.completer)
      : timestamp = DateTime.now();
}

/// Internal class to hold refresh result
class _RefreshResult {
  final bool success;
  final String? token;

  _RefreshResult({required this.success, this.token});
}

/// Authentication interceptor for NetGuard with improved queue management
class AuthInterceptor extends QueuedInterceptor {
  final AuthCallbacks _callbacks;
  final AuthConfig _config;

  bool _isRefreshing = false;
  final List<_PendingAuthRequest> _pendingAuthRequests = [];
  Completer<String?>? _refreshCompleter;

  AuthInterceptor({
    required AuthCallbacks callbacks,
    AuthConfig config = const AuthConfig(),
  }) : _callbacks = callbacks, _config = config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    _log('🔐 Processing request: ${options.method} ${options.path}');

    try {
      // Get token and add to headers if available
      final token = await _callbacks.getToken();
      if (token != null && token.isNotEmpty) {
        final headerValue = '${_config.tokenPrefix}$token';
        options.headers[_config.tokenHeaderName] = headerValue;
        _log('✅ Token added to request headers');
      } else {
        _log('ℹ️ No token available, proceeding without authentication');
      }

      handler.next(options);
    } catch (e) {
      _log('❌ Error getting token: $e');
      handler.next(options); // Proceed without token
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log('✅ Response received: ${response.statusCode} for ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    _log('⚠️ Error intercepted: ${err.response?.statusCode} for ${err.requestOptions.path}');

    // Check if this is a 401 Unauthorized error
    if (err.response?.statusCode == 401 && _config.autoRefresh) {
      _log('🔄 401 Unauthorized detected, attempting token refresh...');

      // If already refreshing, queue this request
      if (_isRefreshing) {
        _log('⏳ Token refresh in progress, queuing request...');
        _queueAuthRequest(err.requestOptions, handler);
        return;
      }

      // Attempt token refresh
      final refreshResult = await _attemptTokenRefresh();

      if (refreshResult.success && refreshResult.token != null) {
        _log('✅ Token refresh successful, retrying original request...');

        // Update the original request with new token
        final newToken = refreshResult.token!;
        final headerValue = '${_config.tokenPrefix}$newToken';
        err.requestOptions.headers[_config.tokenHeaderName] = headerValue;

        // Retry the original request
        try {
          final dio = Dio();
          final response = await dio.fetch(err.requestOptions);
          _log('✅ Original request retry successful');
          handler.resolve(response);
          return;
        } catch (retryError) {
          _log('❌ Original request retry failed: $retryError');
          if (retryError is DioException) {
            handler.next(retryError);
          } else {
            handler.next(DioException(
              requestOptions: err.requestOptions,
              error: retryError,
              type: DioExceptionType.unknown,
            ));
          }
          return;
        }
      } else {
        _log('❌ Token refresh failed, triggering logout...');
        // Token refresh failed, trigger logout
        try {
          await _callbacks.onLogout();
        } catch (logoutError) {
          _log('❌ Logout callback failed: $logoutError');
        }
      }
    }

    // For non-401 errors or when refresh is disabled/failed
    handler.next(err);
  }

  /// Queue a request while token refresh is in progress
  void _queueAuthRequest(RequestOptions options, ErrorInterceptorHandler handler) {
    final completer = Completer<Response>();
    _pendingAuthRequests.add(_PendingAuthRequest(options, handler, completer));

    // Wait for the refresh to complete, then handle the queued request
    completer.future.then((response) {
      handler.resolve(response);
    }).catchError((error) {
      if (error is DioException) {
        handler.next(error);
      } else {
        handler.next(DioException(
          requestOptions: options,
          error: error,
          type: DioExceptionType.unknown,
        ));
      }
    });
  }

  /// Attempt to refresh the token with improved queue handling
  /// This ensures onRefreshToken is called only once, even with multiple 401s
  Future<_RefreshResult> _attemptTokenRefresh() async {
    // If already refreshing, wait for the ongoing refresh
    if (_isRefreshing) {
      try {
        final token = await _refreshCompleter?.future;
        return _RefreshResult(success: token != null, token: token);
      } catch (e) {
        return _RefreshResult(success: false);
      }
    }

    // Start the refresh process
    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();
    _log('🔄 Starting token refresh process...');

    try {
      int attempts = 0;
      String? newToken;

      while (attempts < _config.maxRetryAttempts) {
        attempts++;
        _log('🔄 Token refresh attempt $attempts/${_config.maxRetryAttempts}');

        try {
          // This is where onRefreshToken is called - only once per refresh cycle
          newToken = await _callbacks.refreshToken();
          if (newToken != null && newToken.isNotEmpty) {
            _log('✅ Token refresh successful on attempt $attempts');
            break;
          } else {
            _log('⚠️ Token refresh returned null/empty token on attempt $attempts');
          }
        } catch (e) {
          _log('❌ Token refresh failed on attempt $attempts: $e');
          if (attempts < _config.maxRetryAttempts) {
            _log('⏳ Waiting ${_config.retryDelay.inMilliseconds}ms before retry...');
            await Future.delayed(_config.retryDelay);
          }
        }
      }

      if (newToken != null && newToken.isNotEmpty) {
        // Notify that token was refreshed
        try {
          await _callbacks.onTokenRefreshed(newToken);
          _log('✅ Token refresh callback completed successfully');
        } catch (e) {
          _log('❌ Token refresh callback failed: $e');
        }

        // Complete the refresh completer with success
        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(newToken);
        }

        // Process any queued requests
        await _processQueuedAuthRequests(newToken);

        return _RefreshResult(success: true, token: newToken);
      } else {
        _log('❌ Token refresh failed after all attempts');

        // Complete the refresh completer with failure
        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(null);
        }

        _clearQueuedAuthRequests();
        return _RefreshResult(success: false);
      }
    } catch (e) {
      _log('❌ Unexpected error during token refresh: $e');

      // Complete the refresh completer with error
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.completeError(e);
      }

      _clearQueuedAuthRequests();
      return _RefreshResult(success: false);
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
      _log('🔄 Token refresh process completed');
    }
  }

  /// Process all queued auth requests with the new token
  Future<void> _processQueuedAuthRequests(String newToken) async {
    if (_pendingAuthRequests.isEmpty) return;

    _log('📋 Processing ${_pendingAuthRequests.length} queued auth requests...');

    final requestsCopy = List<_PendingAuthRequest>.from(_pendingAuthRequests);
    _pendingAuthRequests.clear();

    for (final pendingRequest in requestsCopy) {
      try {
        // Update request with new token
        final headerValue = '${_config.tokenPrefix}$newToken';
        pendingRequest.options.headers[_config.tokenHeaderName] = headerValue;

        // Execute the request
        final dio = Dio();
        final response = await dio.fetch(pendingRequest.options);

        _log('✅ Queued auth request completed successfully: ${pendingRequest.options.path}');
        pendingRequest.completer.complete(response);
      } catch (e) {
        _log('❌ Queued auth request failed: ${pendingRequest.options.path} - $e');
        if (e is DioException) {
          pendingRequest.completer.completeError(e);
        } else {
          pendingRequest.completer.completeError(DioException(
            requestOptions: pendingRequest.options,
            error: e,
            type: DioExceptionType.unknown,
          ));
        }
      }
    }

    _log('✅ All queued auth requests processed');
  }

  /// Clear all queued auth requests (called when refresh fails)
  void _clearQueuedAuthRequests() {
    _log('🗑️ Clearing ${_pendingAuthRequests.length} queued auth requests due to refresh failure');

    for (final pendingRequest in _pendingAuthRequests) {
      pendingRequest.completer.completeError(DioException(
        requestOptions: pendingRequest.options,
        error: 'Token refresh failed',
        type: DioExceptionType.unknown,
        response: Response(
          requestOptions: pendingRequest.options,
          statusCode: 401,
          statusMessage: 'Authentication failed - token refresh unsuccessful',
        ),
      ));
    }

    _pendingAuthRequests.clear();
  }

  /// Log message if logging is enabled
  void _log(String message) {
    if (_config.enableLogging) {
      print('[NetGuard Auth] $message');
    }
  }

  /// Get number of queued auth requests (useful for debugging)
  int get queuedRequestsCount => _pendingAuthRequests.length;

  /// Check if token refresh is currently in progress
  bool get isRefreshing => _isRefreshing;

  /// Clear any pending state (useful for testing or cleanup)
  void clear() {
    _clearQueuedAuthRequests();
    _isRefreshing = false;
    _refreshCompleter?.complete(null);
    _refreshCompleter = null;
  }
}