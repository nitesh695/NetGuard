# NetGuard

A powerful HTTP client for Flutter built on top of Dio with enhanced security and networking capabilities.

## Features

- **Full Dio Compatibility**: NetGuard provides 100% compatibility with Dio's API
- **Enhanced Error Handling**: User-friendly error messages and detailed error information
- **Static Methods**: Convenient static methods for quick API calls
- **Quick Setup**: Easy configuration methods for common use cases
- **Type Safety**: Full TypeScript-like type safety with Dart generics
- **Interceptors**: Full support for Dio's interceptor system
- **File Downloads**: Built-in support for file downloads with progress tracking
- **Certificate Handling**: Easy configuration for SSL certificate validation

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  netguard: ^1.0.0
```

Then run:

```bash
flutter packages get
```

## Quick Start

### Basic Usage

```dart
import 'package:netguard/netguard.dart';

// Create NetGuard instance
final netGuard = NetGuard();

// Configure options
netGuard.options.baseUrl = 'https://api.example.com';
netGuard.options.connectTimeout = const Duration(seconds: 10);

// Make a GET request
final response = await netGuard.get('/users');
print(response.data);

// Make a POST request
final postResponse = await netGuard.post('/users', data: {
  'name': 'John Doe',
  'email': 'john@example.com',
});
```

### Using Static Methods

```dart
import 'package:netguard/netguard.dart';

// Configure the default instance
NetGuard.configure(
  baseUrl: 'https://api.example.com',
  connectTimeout: const Duration(seconds: 10),
);

// Use static methods
final response = await NetGuard.get('/users');
final postResponse = await NetGuard.post('/users', data: {'name': 'John'});
```

### Quick Setup Method

```dart
import 'package:netguard/netguard.dart';

// Quick setup with common configurations
NetGuard.quickSetup(
  baseUrl: 'https://api.example.com',
  accessToken: 'your_access_token',
  timeout: const Duration(seconds: 30),
  allowBadCertificates: true,
  logger: (message) => print(message),
);

// Now you can use static methods
final response = await NetGuard.get('/secure-endpoint');
```

## Advanced Usage

### Custom Configuration (Your Example)

```dart
import 'dart:io';
import 'package:netguard/netguard.dart';

final NetGuard netGuard = NetGuard();
String? accessToken = 'your_token_here';

init() async {
  netGuard.options.baseUrl = 'https://api.example.com';
  netGuard.options.connectTimeout = const Duration(seconds: 10);
  netGuard.options.receiveTimeout = const Duration(seconds: 10);
  netGuard.options.sendTimeout = const Duration(seconds: 10);

  (netGuard.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    client.idleTimeout = const Duration(seconds: 15);
    return client;
  };

  netGuard.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (accessToken?.isNotEmpty == true) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        print("❌ NetGuard error: ${e.message}");
        // Handle error (close loaders, etc.)
        return handler.next(e);
      },
    ),
  );
}

// Usage
void main() async {
  await init();
  
  final response = await netGuard.post(
    '/api/secure-data',
    data: {
      'sensitive_info': 'This will be encrypted',
      'user_id': 12345,
    },
  );
  
  print(response.data);
}
```

### Using with Different HTTP Methods

```dart
// GET request
final getResponse = await netGuard.get('/users', 
  queryParameters: {'page': 1, 'limit': 10}
);

// POST request
final postResponse = await netGuard.post('/users', 
  data: {'name': 'John', 'email': 'john@example.com'}
);

// PUT request
final putResponse = await netGuard.put('/users/1', 
  data: {'name': 'Jane Doe'}
);

// DELETE request
final deleteResponse = await netGuard.delete('/users/1');

// PATCH request
final patchResponse = await netGuard.patch('/users/1', 
  data: {'status': 'active'}
);
```

### File Download

```dart
// Download file with progress tracking
final response = await netGuard.download(
  '/files/document.pdf',
  '/path/to/save/document.pdf',
  onReceiveProgress: (received, total) {
    if (total != -1) {
      double progress = received / total;
      print('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
    }
  },
);
```

### Error Handling

```dart
try {
  final response = await netGuard.get('/api/data');
  print(response.data);
} on DioException catch (e) {
  // NetGuard provides enhanced error information
  print('Error Type: ${e.type}');
  print('Status Code: ${e.statusCode}');
  print('User Friendly Message: ${e.userFriendlyMessage}');
  
  // Check specific error types
  if (e.isNetworkError) {
    print('Network connection issue');
  } else if (e.isTimeoutError) {
    print('Request timed out');
  } else if (e.isServerError) {
    print('Server error occurred');
  }
}
```

### Custom Interceptors

```dart
netGuard.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      // Add custom headers
      options.headers['X-Custom-Header'] = 'custom-value';
      options.headers['X-Timestamp'] = DateTime.now().millisecondsSinceEpoch;
      
      print('Request: ${options.method} ${options.uri}');
      handler.next(options);
    },
    onResponse: (response, handler) {
      print('Response: ${response.statusCode} ${response.requestOptions.uri}');
      handler.next(response);
    },
    onError: (error, handler) {
      print('Error: ${error.message}');
      
      // Custom error handling logic
      if (error.response?.statusCode == 401) {
        // Handle unauthorized error
        print('Unauthorized - redirecting to login');
      }
      
      handler.next(error);
    },
  ),
);
```

### Response Extensions

```dart
final response = await netGuard.get('/api/data');

// Check response status
if (response.isSuccessful) {
  print('Request successful');
} else if (response.isClientError) {
  print('Client error: ${response.statusCode}');
} else if (response.isServerError) {
  print('Server error: ${response.statusCode}');
}

// Check content type
if (response.isJson) {
  print('Response is JSON');
} else if (response.isXml) {
  print('Response is XML');
}

// Get content length
print('Content length: ${response.contentLength}');
```

## API Reference

### NetGuard Class

#### Constructors
- `NetGuard([BaseOptions? options])` - Create a new NetGuard instance
- `NetGuard.fromDio(Dio dio)` - Create NetGuard from existing Dio instance
- `NetGuard.withOptions({...})` - Create NetGuard with custom options

#### Instance Methods
- `get<T>(path, {...})` - Make GET request
- `post<T>(path, {...})` - Make POST request
- `put<T>(path, {...})` - Make PUT request
- `patch<T>(path, {...})` - Make PATCH request
- `delete<T>(path, {...})` - Make DELETE request
- `head<T>(path, {...})` - Make HEAD request
- `download(urlPath, savePath, {...})` - Download file

#### Static Methods
- `NetGuard.get<T>(path, {...})` - Static GET request
- `NetGuard.post<T>(path, {...})` - Static POST request
- `NetGuard.configure({...})` - Configure default instance
- `NetGuard.quickSetup({...})` - Quick setup with common configurations

#### Properties
- `options` - NetGuard options (extends Dio's BaseOptions)
- `interceptors` - NetGuard interceptors wrapper
- `httpClientAdapter` - HTTP client adapter
- `transformer` - Request/response transformer

## Migration from Dio

NetGuard maintains 100% API compatibility with Dio, so migration is straightforward:

```dart
// Before (with Dio)
final dio = Dio();
dio.options.baseUrl = 'https://api.example.com';
final response = await dio.get('/users');

// After (with NetGuard)
final netGuard = NetGuard();
netGuard.options.baseUrl = 'https://api.example.com';
final response = await netGuard.get('/users');
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Changelog

### 1.0.0
- Initial release
- Full Dio compatibility
- Enhanced error handling
- Static methods support
- Quick setup utilities
- Response extensions