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

  /// Cooldown duration for logout function (default: 1 minute)
  final Duration logoutCooldown;

  const AuthConfig({
    this.tokenHeaderName = 'Authorization',
    this.tokenPrefix = 'Bearer ',
    this.maxRetryAttempts = 1,
    this.retryDelay = const Duration(milliseconds: 500),
    this.autoRefresh = true,
    this.enableLogging = false,
    this.logoutCooldown = const Duration(minutes: 1),
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

/// Authentication interceptor for NetGuard with improved queue management and logout cooldown
class AuthInterceptor extends QueuedInterceptor {
  final AuthCallbacks _callbacks;
  final AuthConfig _config;
  late final Dio _dio; // Use a single Dio instance

  bool _isRefreshing = false;
  final List<_PendingAuthRequest> _pendingAuthRequests = [];
  Completer<String?>? _refreshCompleter;

  // Logout cooldown tracking
  DateTime? _lastLogoutTime;

  AuthInterceptor({
    required AuthCallbacks callbacks,
    AuthConfig config = const AuthConfig(),
    Dio? dio, // Optional Dio instance
  }) : _callbacks = callbacks,
        _config = config {
    // Use provided Dio instance or create a new one
    _dio = dio ?? Dio();
  }

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
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    _log('✅ Response received: ${response.statusCode} for ${response.requestOptions.path}');

    // If status is 401 and auto-refresh is enabled, attempt recovery
    final skipAuthRefresh = response.requestOptions.extra['isRefresh'] == true;
    if (response.statusCode == 401 && _config.autoRefresh && !skipAuthRefresh) {
      await _handleUnauthorizedResponse(response, handler);
      return;
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    _log('⚠️ Error intercepted: ${err.response?.statusCode} for ${err.requestOptions.path}');

    // Check if this is a 401 Unauthorized error and auto refresh is enabled
    final skipAuthRefresh = err.requestOptions.extra['isRefresh'] == true;
    if (err.response?.statusCode == 401 && _config.autoRefresh && !skipAuthRefresh) {
      await _handleUnauthorizedError(err, handler);
      return;
    }

    handler.next(err);
  }

  /// Check if logout can be triggered (respects cooldown period)
  bool _canTriggerLogout() {
    if (_lastLogoutTime == null) {
      return true;
    }

    final timeSinceLastLogout = DateTime.now().difference(_lastLogoutTime!);
    final canTrigger = timeSinceLastLogout >= _config.logoutCooldown;

    if (!canTrigger) {
      final remainingCooldown = _config.logoutCooldown - timeSinceLastLogout;
      _log('🚫 Logout cooldown active. ${remainingCooldown.inSeconds} seconds remaining');
    }

    return canTrigger;
  }

  /// Trigger logout with cooldown protection
  Future<bool> _triggerLogoutWithCooldown() async {
    if (!_canTriggerLogout()) {
      _log('⏳ Logout skipped due to cooldown period');
      return false;
    }

    try {
      _log('🔓 Triggering logout...');
      _lastLogoutTime = DateTime.now();
      await _callbacks.onLogout();
      _log('✅ Logout callback completed successfully');
      return true;
    } catch (logoutError) {
      _log('❌ Logout callback failed: $logoutError');
      return false;
    }
  }

  /// Handle unauthorized response (401 from onResponse)
  Future<void> _handleUnauthorizedResponse(
      Response response,
      ResponseInterceptorHandler handler
      ) async {
    _log('🔄 401 Unauthorized detected in response, attempting automatic token refresh...');

    final currentToken = await _callbacks.getToken();
    if (currentToken == null || currentToken.isEmpty) {
      _log('❌ No token available for refresh, checking logout eligibility...');
      await _triggerLogoutForResponse(handler, response.requestOptions);
      return;
    }

    if (_isRefreshing) {
      _log('⏳ Token refresh in progress, queuing request...');
      await _queueResponseRequest(response.requestOptions, handler);
      return;
    }

    final refreshResult = await _attemptTokenRefresh();

    if (refreshResult.success && refreshResult.token != null) {
      _log('✅ Automatic token refresh successful, retrying original request...');
      await _retryRequestFromResponse(refreshResult.token!, response.requestOptions, handler);
    } else {
      _log('❌ Automatic token refresh failed, checking logout eligibility...');
      await _triggerLogoutForResponse(handler, response.requestOptions);
    }
  }

  /// Handle unauthorized error (401 from onError)
  Future<void> _handleUnauthorizedError(
      DioException err,
      ErrorInterceptorHandler handler
      ) async {
    _log('🔄 401 Unauthorized detected in error, attempting automatic token refresh...');

    final currentToken = await _callbacks.getToken();
    if (currentToken == null || currentToken.isEmpty) {
      _log('❌ No token available for refresh, checking logout eligibility...');
      await _triggerLogoutForError(handler, err);
      return;
    }

    if (_isRefreshing) {
      _log('⏳ Token refresh in progress, queuing request...');
      _queueErrorRequest(err.requestOptions, handler);
      return;
    }

    final refreshResult = await _attemptTokenRefresh();

    if (refreshResult.success && refreshResult.token != null) {
      _log('✅ Automatic token refresh successful, retrying original request...');
      await _retryRequestFromError(refreshResult.token!, err, handler);
    } else {
      _log('❌ Automatic token refresh failed, checking logout eligibility...');
      await _triggerLogoutForError(handler, err);
    }
  }

  /// Trigger logout for response handler
  Future<void> _triggerLogoutForResponse(
      ResponseInterceptorHandler handler,
      RequestOptions requestOptions
      ) async {
    final logoutTriggered = await _triggerLogoutWithCooldown();

    // Create a proper error response
    final error = DioException(
      requestOptions: requestOptions,
      error: logoutTriggered ? 'Unauthorized and logout triggered' : 'Unauthorized (logout on cooldown)',
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 401,
        statusMessage: 'Unauthorized',
      ),
    );
    handler.reject(error);
  }

  /// Trigger logout for error handler
  Future<void> _triggerLogoutForError(
      ErrorInterceptorHandler handler,
      DioException originalError
      ) async {
    await _triggerLogoutWithCooldown();
    handler.next(originalError);
  }

  /// Retry request from response handler
  Future<void> _retryRequestFromResponse(
      String newToken,
      RequestOptions originalRequest,
      ResponseInterceptorHandler handler,
      ) async {
    final updatedOptions = _updateRequestWithToken(originalRequest, newToken);

    try {
      final response = await _dio.fetch(updatedOptions);
      _log('✅ Original request retry successful after automatic refresh');
      handler.resolve(response);
    } catch (retryError) {
      _log('❌ Original request retry failed after refresh: $retryError');
      if (retryError is DioException) {
        handler.reject(retryError);
      } else {
        handler.reject(DioException(
          requestOptions: updatedOptions,
          error: retryError,
          type: DioExceptionType.unknown,
        ));
      }
    }
  }

  /// Retry request from error handler
  Future<void> _retryRequestFromError(
      String newToken,
      DioException originalError,
      ErrorInterceptorHandler handler,
      ) async {
    final updatedOptions = _updateRequestWithToken(originalError.requestOptions, newToken);

    try {
      final response = await _dio.fetch(updatedOptions);
      _log('✅ Original request retry successful after automatic refresh');
      handler.resolve(response);
    } catch (retryError) {
      _log('❌ Original request retry failed after refresh: $retryError');
      if (retryError is DioException) {
        handler.next(retryError);
      } else {
        handler.next(DioException(
          requestOptions: updatedOptions,
          error: retryError,
          type: DioExceptionType.unknown,
        ));
      }
    }
  }

  /// Update request options with new token
  RequestOptions _updateRequestWithToken(RequestOptions options, String newToken) {
    // Create a copy of the request options to avoid modifying the original
    final updatedOptions = RequestOptions(
      path: options.path,
      method: options.method,
      data: options.data,
      queryParameters: options.queryParameters,
      headers: Map<String, dynamic>.from(options.headers),
      extra: Map<String, dynamic>.from(options.extra),
      baseUrl: options.baseUrl,
      connectTimeout: options.connectTimeout,
      receiveTimeout: options.receiveTimeout,
      sendTimeout: options.sendTimeout,
      responseType: options.responseType,
      contentType: options.contentType,
      validateStatus: options.validateStatus,
      receiveDataWhenStatusError: options.receiveDataWhenStatusError,
      followRedirects: options.followRedirects,
      maxRedirects: options.maxRedirects,
      persistentConnection: options.persistentConnection,
      requestEncoder: options.requestEncoder,
      responseDecoder: options.responseDecoder,
      listFormat: options.listFormat,
    );

    // Add the new token
    final headerValue = '${_config.tokenPrefix}$newToken';
    updatedOptions.headers[_config.tokenHeaderName] = headerValue;

    return updatedOptions;
  }

  /// Queue a request from response handler
  Future<void> _queueResponseRequest(
      RequestOptions options,
      ResponseInterceptorHandler handler
      ) async {
    final completer = Completer<Response>();
    _pendingAuthRequests.add(_PendingAuthRequest(
        options,
        handler as ErrorInterceptorHandler,
        completer
    ));

    try {
      final response = await completer.future;
      handler.resolve(response);
    } catch (error) {
      if (error is DioException) {
        handler.reject(error);
      } else {
        handler.reject(DioException(
          requestOptions: options,
          error: error,
          type: DioExceptionType.unknown,
        ));
      }
    }
  }

  /// Queue a request from error handler
  void _queueErrorRequest(RequestOptions options, ErrorInterceptorHandler handler) {
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
    _log('🔄 Starting automatic token refresh process...');

    try {
      int attempts = 0;
      String? newToken;

      while (attempts < _config.maxRetryAttempts) {
        attempts++;
        _log('🔄 Automatic token refresh attempt $attempts/${_config.maxRetryAttempts}');

        try {
          _log('📞 Automatically calling refreshToken callback...');
          newToken = await _callbacks.refreshToken();

          if (newToken != null && newToken.isNotEmpty) {
            _log('✅ Automatic token refresh successful on attempt $attempts');
            break;
          } else {
            _log('⚠️ Automatic token refresh returned null/empty token on attempt $attempts');
          }
        } catch (e) {
          _log('❌ Automatic token refresh failed on attempt $attempts: $e');
          if (attempts < _config.maxRetryAttempts) {
            _log('⏳ Waiting ${_config.retryDelay.inMilliseconds}ms before retry...');
            await Future.delayed(_config.retryDelay);
          }
        }
      }

      if (newToken != null && newToken.isNotEmpty) {
        // Notify that token was refreshed
        try {
          _log('📞 Calling onTokenRefreshed callback with new token...');
          await _callbacks.onTokenRefreshed(newToken);
          _log('✅ onTokenRefreshed callback completed successfully');
        } catch (e) {
          _log('❌ onTokenRefreshed callback failed: $e');
        }

        // Complete the refresh completer with success
        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(newToken);
        }

        // Process any queued requests
        await _processQueuedAuthRequests(newToken);

        return _RefreshResult(success: true, token: newToken);
      } else {
        _log('❌ Automatic token refresh failed after all attempts');

        // Complete the refresh completer with failure
        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(null);
        }

        _clearQueuedAuthRequests();
        return _RefreshResult(success: false);
      }
    } catch (e) {
      _log('❌ Unexpected error during automatic token refresh: $e');

      // Complete the refresh completer with error
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.completeError(e);
      }

      _clearQueuedAuthRequests();
      return _RefreshResult(success: false);
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
      _log('🔄 Automatic token refresh process completed');
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
        final updatedOptions = _updateRequestWithToken(pendingRequest.options, newToken);

        // Execute the request
        final response = await _dio.fetch(updatedOptions);

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

  /// Get the time when logout was last triggered (null if never triggered)
  DateTime? get lastLogoutTime => _lastLogoutTime;

  /// Get remaining cooldown time for logout (null if no cooldown active)
  Duration? get logoutCooldownRemaining {
    if (_lastLogoutTime == null) return null;

    final timeSinceLastLogout = DateTime.now().difference(_lastLogoutTime!);
    final remainingCooldown = _config.logoutCooldown - timeSinceLastLogout;

    return remainingCooldown.isNegative ? null : remainingCooldown;
  }

  /// Manually reset logout cooldown (useful for testing or specific scenarios)
  // void resetLogoutCooldown() {
  //   _lastLogoutTime = null;
  //   _log('🔄 Logout cooldown manually reset');
  // }

  /// Clear any pending state (useful for testing or cleanup)
  void clear() {
    _clearQueuedAuthRequests();
    _isRefreshing = false;
    _refreshCompleter?.complete(null);
    _refreshCompleter = null;
    _lastLogoutTime = null;
  }
}