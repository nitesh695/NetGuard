import 'package:dio/dio.dart';
import 'package:netguard/src/utils/util.dart';
import '../netguard.dart';
import 'network_managers/network_service.dart';

/// NetGuard - A powerful HTTP client built on top of Dio
class NetGuard extends NetGuardBase {
  /// Default NetGuard instance for static methods
  static NetGuard? _defaultInstance;

  final AuthManager _authManager = AuthManager();

  /// Create a new NetGuard instance
  NetGuard([BaseOptions? options]) : super(options) {
    // Always initialize network service when NetGuard is created
    _initializeNetworkServiceEarly();
  }

  /// Create NetGuard from existing Dio instance
  NetGuard.fromDio(Dio dio) : super.fromDio(dio) {
    // Always initialize network service when NetGuard is created
    _initializeNetworkServiceEarly();
  }

  /// Get the default NetGuard instance
  static NetGuard get instance {
    _defaultInstance ??= NetGuard();
    return _defaultInstance!;
  }

  /// Initialize network service immediately (non-blocking)
  void _initializeNetworkServiceEarly() {
    NetworkService.instance.initialize().then((success) {
      if (success) {
        logger('🌐 Network service initialized automatically');
      } else {
        logger('❌ Network service auto-initialization failed: ${NetworkService.instance.initializationError}');
      }
    }).catchError((error) {
      logger('❌ Network service auto-initialization error: $error');
    });
  }

  /// Configure authentication
  void configureAuth({
    required AuthCallbacks callbacks,
    AuthConfig config = const AuthConfig(),
  }) {
    _authManager.configure(callbacks: callbacks, config: config);
    _setupAuthInterceptor();
  }

  /// Clear authentication
  void clearAuth() {
    // Remove all AuthInterceptor instances
    final List<Interceptor> filtered = interceptors
        .where((interceptor) => interceptor is! AuthInterceptor)
        .toList();

    interceptors.clear();
    interceptors.addAll(filtered);

    _authManager.clear();
  }

  /// Setup authentication interceptor
  void _setupAuthInterceptor() {
    final authInterceptor = _authManager.interceptor;

    if (authInterceptor != null) {
      final List<Interceptor> filtered = interceptors
          .where((interceptor) => interceptor is! AuthInterceptor)
          .toList();

      interceptors.clear();
      interceptors.addAll(filtered);

      // Add auth interceptor at the beginning
      interceptors.insert(0, authInterceptor);
    }
  }

  /// Update authentication tokens - ADD THIS METHOD
  Future<void> updateAuthTokens({
    required String accessToken,
    String? refreshToken,
  }) async
  {
    if (!_authManager.isConfigured) {
      logger('❌ Auth not configured, cannot update tokens');
      return;
    }

    logger('🔄 Updating auth tokens in NetGuard...');

    // Update tokens in the auth manager
    await _authManager.updateTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    // If using AdvanceAuthCallbacks, also update directly
    if (_authManager.callbacks is AdvanceAuthCallbacks) {
      final callbacks = _authManager.callbacks as AdvanceAuthCallbacks;
      callbacks.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      logger('✅ Tokens updated successfully');
    }
  }

  /// Test authentication flow (useful for debugging) - ADD THIS METHOD
  Future<void> testAuthFlow() async {
    if (!_authManager.isConfigured) {
      logger('❌ Auth not configured for testing');
      return;
    }

    logger('🧪 Testing authentication flow...');

    // Test getting current token
    final currentToken = await _authManager.callbacks?.getToken();
    logger('📋 Current token: ${currentToken?.substring(0, 20) ?? 'null'}...');

    // Test token refresh
    final newToken = await _authManager.testTokenRefresh();
    logger('📋 Refresh result: ${newToken?.substring(0, 20) ?? 'null'}...');

    // Print auth status
    final status = _authManager.getStatus();
    logger('📊 Auth status: $status');
  }

  /// Get authentication status
  Map<String, dynamic> get authStatus => _authManager.getStatus();

  /// Check if user is authenticated (convenience method)
  Future<bool> isAuthenticated() async {
    if (!_authManager.isConfigured) return false;
    final token = await _authManager.callbacks?.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  void close({bool force = false}) {
    clearAuth();
    super.close(force: force);
  }

  /// Create NetGuard with custom options
  factory NetGuard.withOptions({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
    bool? persistentConnection,
    Duration? cacheDuration,
    int? maxCacheSize,
    String Function(dynamic body)? encryptionFunction,
    bool handleNetwork = false,
    bool autoRetryOnNetworkRestore = true,
    int maxNetworkRetries = 3,
    bool throwOnOffline = false,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: headers,
      extra: extra,
      responseType: responseType,
      contentType: contentType,
      validateStatus: validateStatus,
      receiveDataWhenStatusError: receiveDataWhenStatusError,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      requestEncoder: requestEncoder,
      responseDecoder: responseDecoder,
      listFormat: listFormat,
      persistentConnection: persistentConnection,
    );

    final netGuard = NetGuard(options);

    // Set NetGuard-specific options
    if (cacheDuration != null) {
      netGuard.options.cacheDuration = cacheDuration;
    }
    if (maxCacheSize != null) {
      netGuard.options.maxCacheSize = maxCacheSize;
    }
    if (encryptionFunction != null) {
      netGuard.options.encryptionFunction = encryptionFunction;
    }

    netGuard.options.handleNetwork = handleNetwork;
    netGuard.options.autoRetryOnNetworkRestore = autoRetryOnNetworkRestore;
    netGuard.options.maxNetworkRetries = maxNetworkRetries;
    netGuard.options.throwOnOffline = throwOnOffline;

    return netGuard;
  }

  /// Configure the default instance with common settings
  static Future<void> configure({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, dynamic>? headers,
    HttpClientAdapter? httpClientAdapter,
    List<Interceptor>? interceptors,
    Duration? cacheDuration,
    int? maxCacheSize,
    String Function(dynamic body)? encryptionFunction,
    bool handleNetwork = false,
    bool autoRetryOnNetworkRestore = true,
    int maxNetworkRetries = 3,
    bool throwOnOffline = false,
  }) async {
    final netGuard = instance;

    if (baseUrl != null) {
      netGuard.options.baseUrl = baseUrl;
    }

    if (connectTimeout != null) {
      netGuard.options.connectTimeout = connectTimeout;
    }

    if (receiveTimeout != null) {
      netGuard.options.receiveTimeout = receiveTimeout;
    }

    if (sendTimeout != null) {
      netGuard.options.sendTimeout = sendTimeout;
    }

    if (headers != null) {
      netGuard.options.headers.addAll(headers);
    }

    if (httpClientAdapter != null) {
      netGuard.httpClientAdapter = httpClientAdapter;
    }

    if (interceptors != null) {
      netGuard.interceptors.addAll(interceptors);
    }

    if (cacheDuration != null) {
      netGuard.options.cacheDuration = cacheDuration;
    }

    if (maxCacheSize != null) {
      netGuard.options.maxCacheSize = maxCacheSize;
    }

    if (encryptionFunction != null) {
      netGuard.options.encryptionFunction = encryptionFunction;
    }

    netGuard.options.handleNetwork = handleNetwork;
    netGuard.options.autoRetryOnNetworkRestore = autoRetryOnNetworkRestore;
    netGuard.options.maxNetworkRetries = maxNetworkRetries;
    netGuard.options.throwOnOffline = throwOnOffline;
  }

  /// Manually refresh network status
  Future<void> refreshNetworkStatus() async {
    await NetworkService.instance.refresh();
  }

  /// Get network connection info
  Map<String, dynamic> get networkInfo => NetworkService.instance.getConnectionInfo();

  /// Get current network status
  NetworkStatus get networkStatus => NetworkService.instance.currentStatus;

  /// Check if currently online
  bool get isOnline => NetworkService.instance.isOnline;

  /// Check if currently offline
  bool get isOffline => NetworkService.instance.isOffline;

  /// Stream of network status changes - Available immediately without manual initialization
  Stream<NetworkStatus> get statusStream => NetworkService.instance.statusStream;
}