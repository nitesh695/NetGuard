import 'package:dio/dio.dart';
import 'netguard_base.dart';

/// NetGuard - A powerful HTTP client built on top of Dio
///
/// NetGuard provides all the functionality of Dio with additional features
/// and a familiar API that maintains backward compatibility.
///
/// Example usage:
/// ```dart
/// final netGuard = NetGuard();
///
/// // Configure options
/// netGuard.options.baseUrl = 'https://api.example.com';
/// netGuard.options.connectTimeout = const Duration(seconds: 10);
///
/// // Add interceptors
/// netGuard.interceptors.add(InterceptorsWrapper(
///   onRequest: (options, handler) {
///     // Add auth token
///     options.headers['Authorization'] = 'Bearer $token';
///     handler.next(options);
///   },
/// ));
///
/// // Make requests
/// final response = await netGuard.post('/api/data', data: {'key': 'value'});
/// ```
class NetGuard extends NetGuardBase {
  /// Default NetGuard instance for static methods
  static NetGuard? _defaultInstance;

  /// Create a new NetGuard instance
  NetGuard([BaseOptions? options]) : super(options);

  /// Create NetGuard from existing Dio instance
  NetGuard.fromDio(Dio dio) : super.fromDio(dio);

  static NetGuard get instance => _defaultInstance ??= NetGuard();

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

    return netGuard;
  }

  /// Configure the default instance with common settings
  static void configure({
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
  }) {
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
  }
}