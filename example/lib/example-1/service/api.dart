import 'dart:async';
import 'dart:io';
import 'package:get/get.dart' as getx;
import 'package:netguard/netguard.dart';
import '../constants/routes_constants.dart';
import '../utils/route.dart';
import '../utils/storage_manager.dart';

class ApiClient extends getx.GetxService {
  final StorageManager sharedPreferences;
  final NetGuard _netGuard = NetGuard();
  late AdvanceAuthCallbacks _authCallbacks;

  ApiClient({
    required this.sharedPreferences,
  });

  init() async {
    // Configure base options first
    _netGuard.options.baseUrl = 'https://example.com';
    _netGuard.options.connectTimeout = const Duration(seconds: 10);
    _netGuard.options.receiveTimeout = const Duration(seconds: 10);
    _netGuard.options.sendTimeout = const Duration(seconds: 10);



    ///network config.......
    _netGuard.options.handleNetwork = true;
    _netGuard.options.autoRetryOnNetworkRestore = true;
    _netGuard.options.maxNetworkRetries = 3;
    _netGuard.options.throwOnOffline = true;

    // Configure HTTP client adapter
    (_netGuard.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      client.idleTimeout = const Duration(seconds: 15);
      return client;
    };

    // Get stored tokens
    String? storedAccessToken = await sharedPreferences.getToken();
    String? storedRefreshToken = await sharedPreferences.getRefToken();

    print('🔧 Initializing ApiClient with stored tokens:');
    print('   - Access Token: ${(storedAccessToken ?? '').isNotEmpty ? storedAccessToken?.substring(0, 20) : 'EMPTY'}...');
    print('   - Refresh Token: ${(storedRefreshToken ?? '').isNotEmpty ? storedRefreshToken?.substring(0, 20) : 'EMPTY'}...');

    // Create auth callbacks with initial tokens
    _authCallbacks = AdvanceAuthCallbacks(
      initialToken: storedAccessToken,
      initialRefreshToken: storedRefreshToken,
      onRefreshToken: _handleTokenRefresh,
      onTokenRefreshed: _handleTokenRefreshed,
      onLogout: _handleLogout,
    );

    // Configure authentication
    _netGuard.configureAuth(
      callbacks: _authCallbacks,
      config: const AuthConfig(
        enableLogging: false,
        maxRetryAttempts: 1,
        tokenHeaderName: 'Authorization',
        tokenPrefix: 'Bearer ',
        autoRefresh: true,
        retryDelay: Duration(seconds: 60),
      ),
    );

    // Add request/error interceptor for debugging
    _netGuard.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print("📤 Request: ${options.method} ${options.path}");
          print("   Headers: ${options.headers}");

          return handler.next(options);
        },
        onResponse: (response, handler) async {
          print("📥 Response: ${response.statusCode} for ${response.requestOptions.path}");
          return handler.next(response);
        },
        onError: (e, handler) async {
          print("❌ Request Error: ${e.response?.statusCode} - ${e.message}");
          print("   Path: ${e.requestOptions.path}");
          return handler.next(e);
        },
      ),
    );

  }


  Future<String?> _handleTokenRefresh() async {
    print('🔄 _handleTokenRefresh called');

    try {
      // Get current refresh token from storage
      String? currentRefreshToken = await sharedPreferences.getRefToken();

      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        print('❌ No refresh token available in storage');
        return null;
      }

      print('📞 Making refresh token request...');
      print('   Using refresh token: ${currentRefreshToken.substring(0, 20)}...');

      Map<String, String> body = {
        "refresh_token": currentRefreshToken
      };

      // Create a temporary Dio instance for refresh to avoid circular calls
      final tempDio = NetGuard.instance.dio;
      tempDio.options.baseUrl = _netGuard.options.baseUrl!;
      tempDio.options.connectTimeout = _netGuard.options.connectTimeout;
      tempDio.options.receiveTimeout = _netGuard.options.receiveTimeout;

      final response = await tempDio.post(
        "/api/v1/refresh",
        data: body,
        options: Options(
            extra: {'isRefresh': true},
            headers: {
              'Content-Type': 'application/json',
            }

        ),
      );

      print("🔄 Refresh token response: ${response.statusCode}");
      print("📋 Response data: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        String newAccessToken = data['data']['_token']['access_token'] ?? '';
        String newRefreshToken = data['data']['_token']['refresh_token'] ?? currentRefreshToken;

        if (newAccessToken.isNotEmpty) {
          print('✅ Token refresh successful');
          print('   New access token: ${newAccessToken.substring(0, 20)}...');

          // Store new tokens
          await sharedPreferences.setToken(newAccessToken);
          await sharedPreferences.setRefToken(newRefreshToken);

          return newAccessToken;
        } else {
          print('❌ Token refresh failed: no access token in response');
          return null;
        }
      } else {
        print('❌ Token refresh failed: invalid response status ${response.statusCode}');
        return null;
      }

    } catch (e) {
      print('❌ Token refresh error: $e');
      if (e is DioException) {
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
      }
      return null;
    }
  }

  Future<void> _handleTokenRefreshed(String newToken) async {
    print('💾 Token refreshed callback - storing new token');
    print('   New token: ${newToken.substring(0, 20)}...');

    // Update in storage
    await sharedPreferences.setToken(newToken);

    // Update in auth callbacks
    _authCallbacks.updateAccessToken(newToken);
  }

  Future<void> _handleLogout() async {
    print('👋 Logout callback triggered - clearing tokens and redirecting');

    // Clear from storage
    await sharedPreferences.setToken('');
    await sharedPreferences.setRefToken('');

    // Clear from auth callbacks
    _authCallbacks.clearTokens();
    getx.Get.showSnackbar(
      getx.GetSnackBar(
        title: '',
        message: 'logout..',
        duration: const Duration(seconds: 3),
      ),
    );

    // Navigate to login
    letsGoto.pushReplacementNamed(RouteConstants.loginScreen);
  }

  /// Update tokens manually (call this after successful login)
  updateHeader(String token, String ref) async {
    print("🔄 Updating headers with new tokens...");
    print("   Access token: ${token.substring(0, 20)}...");
    print("   Refresh token: ${ref.substring(0, 20)}...");

    // Store in preferences
    await sharedPreferences.setToken(token);
    await sharedPreferences.setRefToken(ref);

    // Update NetGuard auth tokens
    await _netGuard.updateAuthTokens(accessToken: token, refreshToken: ref);


    print("✅ Headers updated successfully");
  }

  Future<Response> safeRequest({
    required String method,
    required String url,
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    bool bypass = false,
    bool showLoader = false,
    bool showError = true,
    bool useCache = false

  }) async {
    try {
      final response = await _performRequest(
        method: method,
        url: url,
        data: data,
        queryParams: queryParams,
        options: options,
        useCache: useCache
      );

      final finalResponse = await handleDioResponse(
        response,
        url,
        bypass: bypass,
        showError: showError,
      );
      return finalResponse;

    } catch (e) {
      rethrow;
    }
  }

  Future<Response> _performRequest({
    required String method,
    required String url,
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    bool? useCache = false
  }) async {
    return await _netGuard.request(
      url,
      data: data,
      queryParameters: queryParams,
      options: options?.copyWith(
        method: method,
        validateStatus: (status) => status != null && status < 600,
      ) ?? Options(
        method: method,
        validateStatus: (status) => status != null && status < 600,
      ),
      useCache: useCache ?? false
    );
  }

  Future<Response> get(String url, {
    Map<String, dynamic>? queryParams,
    Options? options,
    bool showLoader = false,
    bool bypass = false,
    bool showError = true,
    bool useCache = false
  }) {
    return safeRequest(
        method: 'GET',
        url: url,
        queryParams: queryParams,
        options: options,
        showLoader: showLoader,
        bypass: bypass,
        showError: showError,
      useCache: useCache
    );
  }

  Future<Response> post(String url, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    bool showLoader = true,
    bool bypass = false,
    bool showError = true,
  }) async {
    return safeRequest(
      method: 'POST',
      url: url,
      data: data,
      queryParams: queryParams,
      options: options,
      showLoader: showLoader,
      bypass: bypass,
      showError: showError,
    );
  }

  Future<Response> patch(String url, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    bool showLoader = true,
    bool bypass = false
  }) {
    return safeRequest(
      method: 'PATCH',
      url: url,
      data: data,
      queryParams: queryParams,
      options: options,
      showLoader: showLoader,
      bypass: bypass,
    );
  }

  Future<Response> put(String url, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    bool showLoader = true
  }) {
    return safeRequest(
      method: 'PUT',
      url: url,
      data: data,
      queryParams: queryParams,
      options: options,
      showLoader: showLoader,
    );
  }

  Future<Response> delete(String url, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    bool showLoader = true
  }) {
    return safeRequest(
      method: 'DELETE',
      url: url,
      data: data,
      queryParams: queryParams,
      options: options,
      showLoader: showLoader,
    );
  }

  Future<Response> uploadMultipart(String url, Map<String, dynamic> fields, List<MultipartFile> files, {
    Options? options,
    bool showLoader = true
  }) {
    final formData = FormData.fromMap(fields..addAll({'files': files}));
    return safeRequest(
      method: 'POST',
      url: url,
      data: formData,
      options: options ?? Options(contentType: 'multipart/form-data'),
      showLoader: showLoader,
    );
  }

  Future<Response> handleDioResponse(Response response, String uri, {
    bool bypass = false,
    bool showError = true
  }) async {
    try {
      final statusCode = response.statusCode ?? 0;
      final body = response.data;
      String message = '';

      switch (statusCode) {
        case 400:
        case >= 402 && < 500:
          message = body is Map ? (body['message']?.toString() ?? 'Unknown error') : 'Unknown error';
          if (showError) {
            print(message);
          }
          break;

        case 401:
          message = body is Map ? (body['message']?.toString() ?? 'Unauthorized') : 'Unauthorized';
          if (showError) {
            print(message);
          }
          break;

        case 500:
          message = 'Internal Server Error!';
          if (showError) {
            print(message);
          }
          break;

        case 200:
          if (body is Map && (body['statusCode'] ?? 0) > 401) {
            message = body['message']?.toString() ?? 'Unknown issue';
            if (!bypass) {
              if (showError) {
                print(message);
              }
            }
          }
          break;

        default:
          if (statusCode >= 400) {
            message = 'HTTP Error: $statusCode';
            if (showError) {
              print(message);
            }
          }
      }

      print('====> API Response: [$statusCode] $uri\n${body.toString()}');
      return response;

    } catch (e) {
      print('handleDioResponse error ==> $e');
      print('Response handling failed');
      return response;
    }
  }

  // Cleanup method to be called when service is disposed
  @override
  void onClose() {
    _netGuard.close();
    super.onClose();
  }
}