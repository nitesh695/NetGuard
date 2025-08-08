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
- [Examples](#-examples)
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

### Basic Authentication Setup

```dart
class AuthService {
  final NetGuard _netGuard = NetGuard();
  
  void configureAuth() {
    _netGuard.configureAuth(
      callbacks: AdvanceAuthCallbacks(
        initialToken: 'your_access_token',
        initialRefreshToken: 'your_refresh_token',
        onRefreshToken: _refreshToken,
        onTokenRefreshed: _onTokenRefreshed,
        onLogout: _onLogout,
      ),
      config: const AuthConfig(
        enableLogging: true,
        tokenHeaderName: 'Authorization',
        tokenPrefix: 'Bearer ',
        maxRetryAttempts: 2,
        autoRefresh: true,
      ),
    );
  }
  
  Future<String?> _refreshToken() async {
    try {
      // Make refresh token API call
      final refreshClient = NetGuard.withOptions(
        baseUrl: _netGuard.options.baseUrl,
      );
      
      final response = await refreshClient.post('/auth/refresh', data: {
        'refresh_token': await _getStoredRefreshToken(),
      });
      
      if (response.statusCode == 200) {
        return response.data['access_token'];
      }
      return null;
    } catch (e) {
      print('Token refresh failed: $e');
      return null;
    }
  }
  
  Future<void> _onTokenRefreshed(String newToken) async {
    // Store the new token
    await _storeToken(newToken);
    print('Token refreshed and stored');
  }
  
  Future<void> _onLogout() async {
    // Clear stored tokens
    await _clearTokens();
    // Navigate to login screen
    NavigationService.navigateToLogin();
  }
}
```

### Advanced Authentication Configuration

```dart
// More customized auth configuration
_netGuard.configureAuth(
  callbacks: AdvanceAuthCallbacks(
    initialToken: initialAccessToken,
    initialRefreshToken: initialRefreshToken,
    onRefreshToken: () async {
      // Your custom refresh logic
      return await performTokenRefresh();
    },
    onTokenRefreshed: (newToken) async {
      // Handle new token
      await updateStoredToken(newToken);
      // Update UI state if needed
      authProvider.updateToken(newToken);
    },
    onLogout: () async {
      // Custom logout logic
      await clearUserData();
      await navigateToLogin();
    },
  ),
  config: const AuthConfig(
    enableLogging: true,
    tokenHeaderName: 'Authorization',
    tokenPrefix: 'Bearer ',
    maxRetryAttempts: 3,
    retryDelay: Duration(seconds: 1),
    autoRefresh: true,
    logoutCooldown: Duration(minutes: 2),
  ),
);
```

### Manual Token Management

```dart
// Update tokens manually
await _netGuard.updateAuthTokens(
  accessToken: 'new_access_token',
  refreshToken: 'new_refresh_token',
);

// Check authentication status
final isAuthenticated = await _netGuard.isAuthenticated();

// Get auth status details
final authStatus = _netGuard.authStatus;
print('Auth configured: ${authStatus['configured']}');
print('Token refreshing: ${authStatus['isRefreshing']}');
```

## 🌐 Network Handling

NetGuard can intelligently handle network connectivity issues with automatic queuing and retry mechanisms.

### Enable Network Handling

```dart
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
class NetworkAwareWidget extends StatefulWidget {
  @override
  _NetworkAwareWidgetState createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  final NetGuard _netGuard = NetGuard.instance;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to network status changes
    _netGuard.statusStream.listen((status) {
      switch (status) {
        case NetworkStatus.online:
          print('✅ Network is online');
          _showSnackBar('Connected to internet');
          break;
        case NetworkStatus.offline:
          print('❌ Network is offline');
          _showSnackBar('No internet connection');
          break;
        case NetworkStatus.unknown:
          print('❓ Network status unknown');
          break;
      }
    });
  }
  
  Future<void> _makeNetworkAwareRequest() async {
    try {
      // This request will be automatically queued if offline
      final response = await _netGuard.get('/data');
      
      // Handle response
      setState(() {
        data = response.data;
      });
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 503) {
        // Handle offline scenario
        _showSnackBar('Request queued - will retry when online');
      }
    }
  }
  
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Network status indicator
          Container(
            color: _netGuard.isOnline ? Colors.green : Colors.red,
            child: Text(
              _netGuard.isOnline ? 'Online' : 'Offline',
              style: TextStyle(color: Colors.white),
            ),
          ),
          
          // Your content
          ElevatedButton(
            onPressed: _makeNetworkAwareRequest,
            child: Text('Make Request'),
          ),
        ],
      ),
    );
  }
}
```

### Manual Network Operations

```dart
// Check network status
if (_netGuard.isOnline) {
  // Make request
} else {
  // Handle offline state
}

// Get detailed network info
final networkInfo = _netGuard.networkInfo;
print('Network status: ${networkInfo['status']}');
print('Is monitoring: ${networkInfo['isMonitoring']}');

// Manually refresh network status
await _netGuard.refreshNetworkStatus();

// Get queued requests count
print('Queued requests: ${_netGuard.queuedRequestsCount}');
```

## 💾 Caching

NetGuard provides intelligent caching that works across all platforms (mobile, web, desktop).

### Enable Caching

```dart
final netGuard = NetGuard.withOptions(
  baseUrl: 'https://api.example.com',
  cacheDuration: const Duration(minutes: 10),
  maxCacheSize: 100,
);

// Use cache in requests
final response = await netGuard.get('/posts', useCache: true);
```

### Cache Management

```dart
// Check cache status
final cacheStats = CacheManager.getStats();
print('Platform: ${cacheStats['platform']}');
print('Cached entries: ${cacheStats['entryCount']}');
print('Storage type: ${cacheStats['storage']}');

// Clear all cache
await CacheManager.clearAll();

// Check if cache is initialized
if (CacheManager.isInitialized) {
  print('Cache is ready');
}
```

### Background Cache Updates

When caching is enabled, NetGuard automatically performs background updates:

```dart
// This will:
// 1. Return cached data immediately if available
// 2. Fetch fresh data in background
// 3. Update cache with new data
final response = await netGuard.get('/posts', useCache: true);
```

## 🔒 Request Encryption

Secure your requests with built-in encryption capabilities.

### Basic Encryption

```dart
// Enable encryption for a request
final response = await netGuard.post(
  '/sensitive-data',
  data: {
    'personal_info': 'sensitive data',
    'user_id': 12345,
  },
  encryptBody: true, // Encrypts the request body
);
```

### Custom Encryption Function

```dart
// Define custom encryption
netGuard.options.encryptionFunction = (dynamic body) {
  final json = jsonEncode(body);
  
  // Your custom encryption logic
  final encrypted = MyEncryption.encrypt(json);
  
  return encrypted;
};

// Use custom encryption
final response = await netGuard.post('/data', 
  data: sensitiveData,
  encryptBody: true,
);
```

## 🚨 Error Handling

NetGuard provides comprehensive error handling with user-friendly messages.

### Basic Error Handling

```dart
try {
  final response = await netGuard.get('/endpoint');
  // Handle success
} on DioException catch (e) {
  // NetGuard extends Dio exceptions with additional helpers
  
  if (e.isNetworkError) {
    print('Network error: ${e.userFriendlyMessage}');
  } else if (e.isTimeoutError) {
    print('Timeout error: ${e.userFriendlyMessage}');
  } else if (e.isClientError) {
    print('Client error (4xx): ${e.userFriendlyMessage}');
  } else if (e.isServerError) {
    print('Server error (5xx): ${e.userFriendlyMessage}');
  } else {
    print('Other error: ${e.userFriendlyMessage}');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

### Advanced Error Handling

```dart
class ApiErrorHandler {
  static void handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        _showError('Connection timeout - please check your internet');
        break;
      case DioExceptionType.connectionError:
        _showError('No internet connection');
        break;
      case DioExceptionType.badResponse:
        _handleBadResponse(error);
        break;
      default:
        _showError(error.userFriendlyMessage);
    }
  }
  
  static void _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = error.response?.data?['message'] ?? 'Unknown error';
    
    switch (statusCode) {
      case 401:
        // Handle unauthorized - NetGuard will auto-refresh if configured
        _showError('Please log in again');
        break;
      case 403:
        _showError('Access denied: $message');
        break;
      case 404:
        _showError('Resource not found');
        break;
      case 422:
        _handleValidationErrors(error.response?.data);
        break;
      default:
        _showError('Server error: $message');
    }
  }
}
```

## ⚙️ Advanced Configuration

### Complete Configuration Example

```dart
final netGuard = NetGuard.withOptions(
  // Basic configuration
  baseUrl: 'https://api.example.com',
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  sendTimeout: const Duration(seconds: 30),
  
  // Headers
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'MyApp/1.0',
  },
  
  // Caching
  cacheDuration: const Duration(minutes: 15),
  maxCacheSize: 200,
  
  // Network handling
  handleNetwork: true,
  autoRetryOnNetworkRestore: true,
  maxNetworkRetries: 5,
  throwOnOffline: false,
  
  // Custom encryption
  encryptionFunction: (body) {
    return MyCustomEncryption.encrypt(jsonEncode(body));
  },
);
```

### Interceptors

```dart
// Add custom interceptors
netGuard.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      // Add custom headers
      options.headers['X-Request-ID'] = generateRequestId();
      options.headers['X-Timestamp'] = DateTime.now().toIso8601String();
      
      print('🚀 Request: ${options.method} ${options.uri}');
      return handler.next(options);
    },
    onResponse: (response, handler) {
      print('✅ Response: ${response.statusCode} ${response.requestOptions.uri}');
      return handler.next(response);
    },
    onError: (error, handler) {
      print('❌ Error: ${error.message}');
      
      // Custom error handling
      if (error.response?.statusCode == 429) {
        // Handle rate limiting
        return handler.reject(error);
      }
      
      return handler.next(error);
    },
  ),
);
```

### SSL Configuration

```dart
import 'dart:io';
import 'package:dio/io.dart';

// Configure SSL for mobile/desktop
(netGuard.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  
  // Accept all certificates (for development only)
  client.badCertificateCallback = (cert, host, port) => true;
  
  // Custom certificate validation
  client.badCertificateCallback = (cert, host, port) {
    return host == 'trusted-domain.com';
  };
  
  // Set timeouts
  client.idleTimeout = const Duration(seconds: 30);
  
  return client;
};
```

## 📖 Examples

### Complete Login Flow with Authentication

```dart
class AuthService {
  final NetGuard _netGuard = NetGuard();
  
  Future<void> initialize() async {
    _netGuard.options.baseUrl = 'https://api.myapp.com';
    
    // Load stored tokens
    final accessToken = await _getStoredToken();
    final refreshToken = await _getStoredRefreshToken();
    
    if (accessToken != null) {
      _configureAuth(accessToken, refreshToken);
    }
  }
  
  Future<LoginResult> login(String email, String password) async {
    try {
      final response = await _netGuard.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      
      // Store tokens
      await _storeTokens(accessToken, refreshToken);
      
      // Configure authentication
      _configureAuth(accessToken, refreshToken);
      
      return LoginResult.success();
    } catch (e) {
      return LoginResult.failure(e.toString());
    }
  }
  
  void _configureAuth(String accessToken, String? refreshToken) {
    _netGuard.configureAuth(
      callbacks: AdvanceAuthCallbacks(
        initialToken: accessToken,
        initialRefreshToken: refreshToken,
        onRefreshToken: () async {
          final storedRefreshToken = await _getStoredRefreshToken();
          if (storedRefreshToken == null) return null;
          
          try {
            final response = await _netGuard.post('/auth/refresh', data: {
              'refresh_token': storedRefreshToken,
            });
            
            return response.data['access_token'];
          } catch (e) {
            return null;
          }
        },
        onTokenRefreshed: (newToken) async {
          await _storeToken(newToken);
        },
        onLogout: () async {
          await _clearTokens();
          // Navigate to login
          AppRouter.navigateToLogin();
        },
      ),
      config: const AuthConfig(
        enableLogging: true,
        autoRefresh: true,
        maxRetryAttempts: 2,
      ),
    );
  }
  
  Future<void> logout() async {
    try {
      await _netGuard.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _clearTokens();
      _netGuard.clearAuth();
    }
  }
}
```

### Network-Aware Data Service

```dart
class PostService {
  final NetGuard _netGuard = NetGuard.withOptions(
    baseUrl: 'https://api.blog.com',
    handleNetwork: true,
    autoRetryOnNetworkRestore: true,
    maxNetworkRetries: 3,
    cacheDuration: const Duration(minutes: 5),
    maxCacheSize: 50,
  );
  
  Future<List<Post>> getPosts({bool forceRefresh = false}) async {
    try {
      final response = await _netGuard.get(
        '/posts',
        useCache: !forceRefresh,
      );
      
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Post.fromJson(json))
            .toList();
      } else if (response.statusCode == 503) {
        // Network error - request was queued
        throw NetworkException('No internet connection. Request queued for retry.');
      }
      
      throw ApiException('Failed to load posts');
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Post> createPost(Post post) async {
    final response = await _netGuard.post(
      '/posts',
      data: post.toJson(),
      encryptBody: true, // Encrypt sensitive data
    );
    
    return Post.fromJson(response.data);
  }
  
  Future<void> deletePost(int id) async {
    await _netGuard.delete('/posts/$id');
  }
}
```

### File Upload with Progress

```dart
class FileUploadService {
  final NetGuard _netGuard = NetGuard();
  
  Future<UploadResult> uploadFile(
    File file, {
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'metadata': jsonEncode({
          'originalName': fileName,
          'size': await file.length(),
          'uploadedAt': DateTime.now().toIso8601String(),
        }),
      });
      
      final response = await _netGuard.post(
        '/upload',
        data: formData,
        onSendProgress: (sent, total) {
          final progress = sent / total;
          onProgress?.call(progress);
          print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );
      
      return UploadResult.success(response.data['file_url']);
    } catch (e) {
      return UploadResult.failure(e.toString());
    }
  }
  
  Future<void> downloadFile(
    String url,
    String savePath, {
    Function(double)? onProgress,
  }) async {
    await _netGuard.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = received / total;
          onProgress?.call(progress);
          print('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
        }
      },
    );
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
- `get<T>(path, {...})` - GET request
- `post<T>(path, {...})` - POST request
- `put<T>(path, {...})` - PUT request
- `patch<T>(path, {...})` - PATCH request
- `delete<T>(path, {...})` - DELETE request
- `download(url, savePath, {...})` - File download
- `request<T>(path, {...})` - Generic request

#### Authentication
- `configureAuth({callbacks, config})` - Configure authentication
- `updateAuthTokens({accessToken, refreshToken})` - Update tokens
- `isAuthenticated()` - Check if authenticated
- `clearAuth()` - Clear authentication
- `authStatus` - Get authentication status

#### Network Handling
- `networkStatus` - Current network status
- `isOnline` - Check if online
- `isOffline` - Check if offline
- `statusStream` - Network status changes stream
- `refreshNetworkStatus()` - Manually refresh network status
- `queuedRequestsCount` - Number of queued requests

### AuthConfig Class

Configuration for authentication behavior:

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

### AdvanceAuthCallbacks Class

Advanced authentication callbacks:

```dart
AdvanceAuthCallbacks({
  String? initialToken,
  String? initialRefreshToken,
  Future<String?> Function()? onRefreshToken,
  Future<void> Function(String newToken)? onTokenRefreshed,  
  Future<void> Function()? onLogout,
});
```

### CacheManager Class

Static methods for cache management:

- `CacheManager.getStats()` - Get cache statistics
- `CacheManager.clearAll()` - Clear all cached data
- `CacheManager.isInitialized` - Check if cache is ready

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on top of the excellent [Dio](https://pub.dev/packages/dio) HTTP client
- Inspired by the need for a more feature-rich HTTP client for Flutter applications

## 📞 Support

- 📖 [Documentation](https://pub.dev/documentation/netguard/latest/)
- 🐛 [Issue Tracker](https://github.com/yourorg/netguard/issues)
- 💬 [Discussions](https://github.com/yourorg/netguard/discussions)

---

Made with ❤️ for the Flutter community