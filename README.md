# NetGuard 🛡️

A powerful and feature-rich HTTP client for Flutter and Dart, built on top of Dio with advanced capabilities including automatic authentication, intelligent caching, network handling, and request encryption.

## ✨ Features

- 🔐 **Advanced Authentication Management** - Automatic token refresh, logout handling, and retry mechanisms
- 🌐 **Intelligent Network Handling** - Offline request queuing, auto-retry on network restore
- 💾 **Smart Caching System** - Cross-platform caching with automatic expiration
- 🔒 **Request Encryption** - Built-in body encryption with customizable functions
- 🚀 **Easy Integration** - Drop-in replacement for Dio with additional features
- 🎯 **Developer Friendly** - Extensive logging and debugging capabilities
- 📱 **Cross Platform** - Works on iOS, Android, Web, and Desktop

## 📋 Table of Contents

- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Basic Usage](#-basic-usage)
- [Authentication](#-authentication)
- [Network Handling](#-network-handling)
- [Caching](#-caching)
- [Request Encryption](#-request-encryption)
- [Error Handling](#-error-handling)
- [Advanced Configuration](#-advanced-configuration)
- [Real-World Examples](#-real-world-examples)
- [API Reference](#-api-reference)

## 📦 Installation

Add NetGuard to your `pubspec.yaml`:

```yaml
dependencies:
  netguard: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

### Basic Setup

```dart
import 'package:netguard/netguard.dart';

void main() {
  // Configure NetGuard globally
  NetGuard.configure(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
  
  runApp(MyApp());
}
```

### Making Your First Request

```dart
class ApiService {
  final NetGuard _netGuard = NetGuard.instance;
  
  Future<Map<String, dynamic>> getUser(int userId) async {
    try {
      final response = await _netGuard.get('/users/$userId');
      return response.data;
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}
```

## 📚 Basic Usage

### HTTP Methods

NetGuard supports all standard HTTP methods:

```dart
final netGuard = NetGuard();

// GET request
final getResponse = await netGuard.get('/posts');

// POST request
final postResponse = await netGuard.post('/posts', data: {
  'title': 'My Post',
  'body': 'Post content',
  'userId': 1,
});

// PUT request
final putResponse = await netGuard.put('/posts/1', data: {
  'title': 'Updated Post',
  'body': 'Updated content',
});

// DELETE request
final deleteResponse = await netGuard.delete('/posts/1');

// PATCH request
final patchResponse = await netGuard.patch('/posts/1', data: {
  'title': 'Patched Title',
});
```

### Using Static Instance

For simple applications, you can use the static instance:

```dart
// Configure once
NetGuard.configure(baseUrl: 'https://api.example.com');

// Use anywhere in your app
final response = await NetGuard.instance.get('/endpoint');
```

### Custom Instance with Options

```dart
final customNetGuard = NetGuard.withOptions(
  baseUrl: 'https://api.example.com',
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 15),
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
);
```

## 🔐 Authentication

NetGuard provides powerful authentication management with automatic token refresh and logout handling.

### Production-Ready Authentication Setup

```dart
class ApiClient extends GetxService {
  final StorageManager sharedPreferences;
  final NetGuard _netGuard = NetGuard();
  
  ApiClient({required this.sharedPreferences});
  
  Future<void> init() async {
    // Configure base options
    _netGuard.options.baseUrl = 'https://api.yourapp.com';
    _netGuard.options.connectTimeout = const Duration(seconds: 10);
    _netGuard.options.receiveTimeout = const Duration(seconds: 10);
    _netGuard.options.sendTimeout = const Duration(seconds: 10);
    
    // Network configuration
    _netGuard.options.handleNetwork = true;
    _netGuard.options.autoRetryOnNetworkRestore = true;
    _netGuard.options.maxNetworkRetries = 3;
    _netGuard.options.throwOnOffline = true;
    
    // Get stored tokens
    String? storedAccessToken = await sharedPreferences.getToken();
    String? storedRefreshToken = await sharedPreferences.getRefToken();
    
    print('🔧 Initializing with stored tokens:');
    print('   - Access Token: ${_maskToken(storedAccessToken)}');
    print('   - Refresh Token: ${_maskToken(storedRefreshToken)}');
    
    // Configure authentication with callbacks
    _netGuard.configureAuth(
      callbacks: AdvanceAuthCallbacks(
        initialToken: storedAccessToken,
        initialRefreshToken: storedRefreshToken,
        onRefreshToken: _handleTokenRefresh,
        onTokenRefreshed: _handleTokenRefreshed,
        onLogout: _handleLogout,
      ),
      config: const AuthConfig(
        enableLogging: false,
        maxRetryAttempts: 1,
        tokenHeaderName: 'Authorization',
        tokenPrefix: 'Bearer ',
        autoRefresh: true,
        retryDelay: Duration(seconds: 60),
      ),
    );
  }
  
  Future<String?> _handleTokenRefresh() async {
    print('🔄 Token refresh initiated');
    
    try {
      String? currentRefreshToken = await sharedPreferences.getRefToken();
      
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        print('❌ No refresh token available');
        return null;
      }
      
      print('📞 Making refresh request...');
      
      // Create temporary instance for refresh to avoid circular calls
      final tempDio = NetGuard.withOptions(
        baseUrl: _netGuard.options.baseUrl,
      );
      
      final response = await tempDio.post(
        "/api/v1/refresh",
        data: {"refresh_token": currentRefreshToken},
        options: Options(
          extra: {'isRefresh': true},
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        String newAccessToken = data['data']['_token']['access_token'] ?? '';
        String newRefreshToken = data['data']['_token']['refresh_token'] ?? currentRefreshToken;
        
        if (newAccessToken.isNotEmpty) {
          print('✅ Token refresh successful');
          
          // Store new tokens
          await sharedPreferences.setToken(newAccessToken);
          await sharedPreferences.setRefToken(newRefreshToken);
          
          return newAccessToken;
        }
      }
      
      print('❌ Token refresh failed: invalid response');
      return null;
      
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
    print('💾 Token refreshed - storing new token');
    await sharedPreferences.setToken(newToken);
  }
  
  Future<void> _handleLogout() async {
    print('👋 Logout triggered - clearing tokens');
    
    // Clear tokens from storage
    await sharedPreferences.setToken('');
    await sharedPreferences.setRefToken('');
    
    // Show logout message
    Get.showSnackbar(GetSnackBar(
      title: '',
      message: 'Session expired. Please login again.',
      duration: const Duration(seconds: 3),
    ));
    
    // Navigate to login
    Get.offAllNamed(RouteConstants.loginScreen);
  }
  
  /// Update tokens after successful login
  Future<void> updateTokens(String accessToken, String refreshToken) async {
    print("🔄 Updating tokens...");
    
    // Store in preferences
    await sharedPreferences.setToken(accessToken);
    await sharedPreferences.setRefToken(refreshToken);
    
    // Update NetGuard auth tokens
    await _netGuard.updateAuthTokens(
      accessToken: accessToken, 
      refreshToken: refreshToken
    );
    
    print("✅ Tokens updated successfully");
  }
  
  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return 'EMPTY';
    return token.length > 20 ? '${token.substring(0, 20)}...' : token;
  }
}
```

### Simple Authentication Setup

For simpler applications, you can use a more straightforward approach:

```dart
class SimpleAuthService {
  final NetGuard _netGuard = NetGuard();
  
  void configureAuth() {
    _netGuard.configureAuth(
      callbacks: AdvanceAuthCallbacks(
        initialToken: 'your_access_token',
        initialRefreshToken: 'your_refresh_token',
        onRefreshToken: () async {
          // Simple refresh logic
          final response = await _netGuard.post('/auth/refresh', data: {
            'refresh_token': await getStoredRefreshToken(),
          });
          return response.data['access_token'];
        },
        onTokenRefreshed: (newToken) async {
          await storeToken(newToken);
        },
        onLogout: () async {
          await clearTokens();
          navigateToLogin();
        },
      ),
      config: const AuthConfig(
        enableLogging: true,
        autoRefresh: true,
        maxRetryAttempts: 2,
      ),
    );
  }
}
```

## 🌐 Network Handling

NetGuard intelligently handles network connectivity with automatic queuing and retry mechanisms.

### Production Network Configuration

```dart
// Enable comprehensive network handling
final netGuard = NetGuard.withOptions(
  baseUrl: 'https://api.example.com',
  handleNetwork: true,
  autoRetryOnNetworkRestore: true,
  maxNetworkRetries: 3,
  throwOnOffline: false, // Queue requests instead of throwing
);
```

### Network Status Monitoring

```dart
class NetworkAwareService {
  final NetGuard _netGuard = NetGuard.instance;
  StreamSubscription<NetworkStatus>? _networkSubscription;
  
  void initNetworkMonitoring() {
    _networkSubscription = _netGuard.statusStream.listen((status) {
      switch (status) {
        case NetworkStatus.online:
          print('✅ Network restored - processing queued requests');
          _showSnackBar('Connected to internet', Colors.green);
          break;
        case NetworkStatus.offline:
          print('❌ Network lost - queuing requests');
          _showSnackBar('No internet connection', Colors.red);
          break;
        case NetworkStatus.unknown:
          print('❓ Network status unknown');
          break;
      }
    });
  }
  
  Future<ApiResponse> fetchDataWithNetworkHandling() async {
    try {
      final response = await _netGuard.get('/api/data');
      
      return ApiResponse.success(response.data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 503) {
        // Request was queued due to network issues
        return ApiResponse.queued('Request queued - will retry when online');
      }
      return ApiResponse.error(e.toString());
    }
  }
  
  void dispose() {
    _networkSubscription?.cancel();
  }
}
```

### Manual Network Operations

```dart
// Check current network status
if (_netGuard.isOnline) {
  await makeRequest();
} else {
  showOfflineMessage();
}

// Get network information
final networkInfo = _netGuard.networkInfo;
print('Network status: ${networkInfo['status']}');
print('Queued requests: ${_netGuard.queuedRequestsCount}');

// Manually refresh network status
await _netGuard.refreshNetworkStatus();
```

## 💾 Caching

NetGuard provides intelligent caching that works across all platforms.

### Smart Caching Implementation

```dart
class DataService {
  final NetGuard _netGuard = NetGuard.withOptions(
    baseUrl: 'https://api.example.com',
    cacheDuration: const Duration(minutes: 10),
    maxCacheSize: 100,
  );
  
  // Get data with caching
  Future<List<Post>> getPosts({bool forceRefresh = false}) async {
    final response = await _netGuard.get(
      '/posts',
      useCache: !forceRefresh, // Use cache unless force refresh
    );
    
    return (response.data as List)
        .map((json) => Post.fromJson(json))
        .toList();
  }
  
  // Cache management
  Future<void> clearCache() async {
    await CacheManager.clearAll();
  }
  
  void printCacheStats() {
    final stats = CacheManager.getStats();
    print('Cache entries: ${stats['entryCount']}');
    print('Platform: ${stats['platform']}');
    print('Storage type: ${stats['storage']}');
  }
}
```

## 🔒 Request Encryption

Secure sensitive requests with built-in encryption.

```dart
class SecureApiService {
  final NetGuard _netGuard = NetGuard();
  
  void configureEncryption() {
    // Custom encryption function
    _netGuard.options.encryptionFunction = (dynamic body) {
      final json = jsonEncode(body);
      return MyEncryption.encrypt(json); // Your encryption logic
    };
  }
  
  Future<Response> sendSensitiveData(Map<String, dynamic> data) async {
    return await _netGuard.post(
      '/sensitive-endpoint',
      data: data,
      encryptBody: true, // Enable encryption for this request
    );
  }
}
```

## 🚨 Error Handling

NetGuard provides comprehensive error handling with detailed response management.

### Production Error Handling

```dart
class ApiClient {
  Future<Response> safeRequest({
    required String method,
    required String url,
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    bool bypass = false,
    bool showError = true,
    bool useCache = false,
  }) async {
    try {
      final response = await _performRequest(
        method: method,
        url: url,
        data: data,
        queryParams: queryParams,
        options: options,
        useCache: useCache,
      );

      return await _handleResponse(
        response,
        url,
        bypass: bypass,
        showError: showError,
      );
    } catch (e) {
      print('❌ Request failed: $e');
      rethrow;
    }
  }
  
  Future<Response> _handleResponse(
    Response response, 
    String uri, {
    bool bypass = false,
    bool showError = true,
  }) async {
    final statusCode = response.statusCode ?? 0;
    final body = response.data;
    String message = '';

    switch (statusCode) {
      case 400:
      case >= 402 && < 500:
        message = body is Map ? 
          (body['message']?.toString() ?? 'Client error') : 
          'Bad request';
        if (showError) _showError(message);
        break;

      case 401:
        message = body is Map ? 
          (body['message']?.toString() ?? 'Unauthorized') : 
          'Authentication required';
        if (showError) _showError(message);
        break;

      case 500:
        message = 'Internal server error occurred';
        if (showError) _showError(message);
        break;

      case 200:
        // Handle nested error codes in successful responses
        if (body is Map && (body['statusCode'] ?? 0) > 401) {
          message = body['message']?.toString() ?? 'Unknown issue';
          if (!bypass && showError) _showError(message);
        }
        break;

      default:
        if (statusCode >= 400) {
          message = 'HTTP Error: $statusCode';
          if (showError) _showError(message);
        }
    }

    print('====> API Response: [$statusCode] $uri');
    return response;
  }
}
```

### User-Friendly Error Messages

```dart
class ErrorHandler {
  static void handleApiError(DioException error) {
    String userMessage = '';
    
    if (error.isNetworkError) {
      userMessage = 'No internet connection. Please check your network.';
    } else if (error.isTimeoutError) {
      userMessage = 'Request timed out. Please try again.';
    } else if (error.isClientError) {
      userMessage = 'Invalid request. Please check your input.';
    } else if (error.isServerError) {
      userMessage = 'Server error occurred. Please try again later.';
    } else {
      userMessage = error.userFriendlyMessage;
    }
    
    _showUserError(userMessage);
  }
}
```

## ⚙️ Advanced Configuration

### Complete Production Setup

```dart
class ProductionApiClient {
  late final NetGuard _netGuard;
  
  Future<void> initialize() async {
    _netGuard = NetGuard.withOptions(
      // Basic configuration
      baseUrl: 'https://api.yourapp.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      
      // Headers
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'YourApp/1.0.0',
      },
      
      // Caching
      cacheDuration: const Duration(minutes: 15),
      maxCacheSize: 200,
      
      // Network handling
      handleNetwork: true,
      autoRetryOnNetworkRestore: true,
      maxNetworkRetries: 5,
      throwOnOffline: false,
    );
    
    // Configure SSL
    _configureSsl();
    
    // Add interceptors
    _setupInterceptors();
  }
  
  void _configureSsl() {
    (_netGuard.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      
      // For production - validate certificates properly
      client.badCertificateCallback = (cert, host, port) {
        // Add your certificate validation logic
        return host == 'api.yourapp.com';
      };
      
      client.idleTimeout = const Duration(seconds: 30);
      return client;
    };
  }
  
  void _setupInterceptors() {
    _netGuard.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add request ID and timestamp
          options.headers['X-Request-ID'] = _generateRequestId();
          options.headers['X-Timestamp'] = DateTime.now().toIso8601String();
          
          print('📤 ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('📥 ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ ${error.response?.statusCode} - ${error.message}');
          
          // Custom error handling
          if (error.response?.statusCode == 429) {
            // Handle rate limiting
            _handleRateLimit(error);
          }
          
          return handler.next(error);
        },
      ),
    );
  }
}
```

## 🏭 Real-World Examples

### Complete Service Implementation

```dart
/// Production-ready API service using NetGuard
class UserService {
  final NetGuard _netGuard;
  final StorageManager _storage;
  
  UserService(this._netGuard, this._storage);
  
  /// Get user profile with caching
  Future<User> getUserProfile({bool forceRefresh = false}) async {
    try {
      final response = await _netGuard.get(
        '/api/v1/user/profile',
        useCache: !forceRefresh,
      );
      
      if (response.statusCode == 200) {
        return User.fromJson(response.data['data']);
      } else if (response.statusCode == 503) {
        throw NetworkException('Request queued - no internet connection');
      }
      
      throw ApiException('Failed to fetch user profile');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update user profile with encryption
  Future<User> updateProfile(UpdateProfileRequest request) async {
    final response = await _netGuard.patch(
      '/api/v1/user/profile',
      data: request.toJson(),
      encryptBody: true, // Encrypt sensitive user data
    );
    
    return User.fromJson(response.data['data']);
  }
  
  /// Upload profile image with progress
  Future<String> uploadProfileImage(
    File imageFile, {
    Function(double)? onProgress,
  }) async {
    final fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
      'metadata': jsonEncode({
        'type': 'profile_image',
        'uploadedAt': DateTime.now().toIso8601String(),
      }),
    });
    
    final response = await _netGuard.post(
      '/api/v1/user/upload-image',
      data: formData,
      onSendProgress: (sent, total) {
        final progress = sent / total;
        onProgress?.call(progress);
      },
    );
    
    return response.data['data']['image_url'];
  }
  
  /// Get users list with pagination and caching
  Future<PaginatedResponse<User>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    bool useCache = true,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
    };
    
    final response = await _netGuard.get(
      '/api/v1/users',
      queryParameters: queryParams,
      useCache: useCache,
    );
    
    return PaginatedResponse<User>.fromJson(
      response.data,
      (json) => User.fromJson(json),
    );
  }
}
```

### Login Flow with Complete Authentication

```dart
class AuthService {
  final NetGuard _netGuard;
  final StorageManager _storage;
  
  AuthService(this._netGuard, this._storage);
  
  Future<LoginResult> login(String email, String password) async {
    try {
      final response = await _netGuard.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
        'device_info': await _getDeviceInfo(),
      });
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final tokens = data['_token'];
        
        final accessToken = tokens['access_token'];
        final refreshToken = tokens['refresh_token'];
        
        // Store tokens
        await _storage.setToken(accessToken);
        await _storage.setRefToken(refreshToken);
        
        // Update NetGuard tokens
        await _netGuard.updateAuthTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        
        return LoginResult.success(User.fromJson(data['user']));
      }
      
      return LoginResult.failure('Login failed');
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? 'Login failed';
        return LoginResult.failure(message);
      }
      return LoginResult.failure(e.toString());
    }
  }
  
  Future<void> logout() async {
    try {
      // Call logout API
      await _netGuard.post('/api/v1/auth/logout');
    } catch (e) {
      // Ignore logout API errors
      print('Logout API call failed: $e');
    } finally {
      // Always clear local data
      await _clearAuthData();
    }
  }
  
  Future<void> _clearAuthData() async {
    await _storage.setToken('');
    await _storage.setRefToken('');
    _netGuard.clearAuth();
  }
}
```

## 📚 API Reference

### NetGuard Class

#### Constructor Options
- `NetGuard([BaseOptions? options])` - Create with optional Dio options
- `NetGuard.fromDio(Dio dio)` - Create from existing Dio instance
- `NetGuard.withOptions({...})` - Create with detailed configuration

#### Static Methods
- `NetGuard.configure({...})` - Configure the default instance
- `NetGuard.instance` - Get the default instance

#### HTTP Methods
- `get<T>(path, {queryParameters, options, useCache, ...})` - GET request
- `post<T>(path, {data, queryParameters, options, encryptBody, ...})` - POST request
- `put<T>(path, {data, queryParameters, options, ...})` - PUT request
- `patch<T>(path, {data, queryParameters, options, ...})` - PATCH request
- `delete<T>(path, {data, queryParameters, options, ...})` - DELETE request
- `download(url, savePath, {onReceiveProgress, ...})` - File download
- `request<T>(path, {options, useCache, ...})` - Generic request

#### Authentication Methods
- `configureAuth({callbacks, config})` - Configure authentication
- `updateAuthTokens({accessToken, refreshToken})` - Update tokens manually
- `isAuthenticated()` - Check authentication status
- `clearAuth()` - Clear authentication configuration
- `authStatus` - Get current authentication status

#### Network Methods
- `networkStatus` - Current network status (online/offline/unknown)
- `isOnline` - Boolean indicating if network is available
- `isOffline` - Boolean indicating if network is unavailable
- `statusStream` - Stream of network status changes
- `refreshNetworkStatus()` - Manually refresh network status
- `queuedRequestsCount` - Number of requests queued due to network issues
- `networkInfo` - Detailed network information

### Configuration Classes

#### AuthConfig
```dart
const AuthConfig({
  String tokenHeaderName = 'Authorization',
  String tokenPrefix = 'Bearer ',
  int maxRetryAttempts = 1,
  Duration retryDelay = const Duration(milliseconds: 500),
  bool autoRefresh = true,
  bool enableLogging = false,
  Duration logoutCooldown = const Duration(minutes: 1),
});
```

#### AdvanceAuthCallbacks
```dart
AdvanceAuthCallbacks({
  String? initialToken,
  String? initialRefreshToken,
  Future<String?> Function()? onRefreshToken,
  Future<void> Function(String newToken)? onTokenRefreshed,
  Future<void> Function()? onLogout,
});
```

### Cache Management

#### CacheManager
- `CacheManager.getStats()` - Returns cache statistics
- `CacheManager.clearAll()` - Clears all cached data
- `CacheManager.isInitialized` - Check if cache system is ready

### Error Extensions

NetGuard extends DioException with helpful properties:
- `isNetworkError` - Network connectivity issues
- `isTimeoutError` - Request timeout
- `isClientError` - 4xx status codes
- `isServerError` - 5xx status codes
- `userFriendlyMessage` - Human-readable error message

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on top of the excellent [Dio](https://pub.dev/packages/dio) HTTP client
- Inspired by real-world Flutter application requirements

## 📞 Support

- 🐛 [Issue Tracker](https://github.com/nitesh695/NetGuard/issues)

---

Made with ❤️ for the Flutter community