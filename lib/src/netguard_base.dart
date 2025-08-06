import 'dart:async';
import 'package:dio/dio.dart';
import 'cache_manager.dart';
import 'netguard_options.dart';
import 'netguard_interceptors.dart';
import 'network_managers/network_interceptor.dart';
import 'network_managers/network_service.dart';

/// Base class for NetGuard that provides all Dio functionality
abstract class NetGuardBase {
  /// The underlying Dio instance
  late final Dio _dio;

  /// NetGuard options that extend Dio's BaseOptions
  late NetGuardOptions options;

  /// Interceptors for NetGuard
  late NetGuardInterceptors interceptors;
  bool _networkInterceptorAdded = false;
  bool _networkInitialized = false;

  /// HTTP client adapter
  HttpClientAdapter get httpClientAdapter => _dio.httpClientAdapter;
  set httpClientAdapter(HttpClientAdapter adapter) =>
      _dio.httpClientAdapter = adapter;

  /// Transformer for request/response
  Transformer get transformer => _dio.transformer;
  set transformer(Transformer transformer) => _dio.transformer = transformer;

  /// Initialize NetGuard with optional base options
  NetGuardBase([BaseOptions? options]) {
    _dio = Dio(options);
    this.options = NetGuardOptions.fromBaseOptions(_dio.options);
    interceptors = NetGuardInterceptors(_dio.interceptors);

    // _initializeNetworkServiceEarly();
    // Set up the callback for when network handling is enabled
    // this.options.setNetworkHandlingCallback(() async {
    //   await _initializeNetworkHandling();
    // });
  }

  /// Initialize NetGuard from existing Dio instance
  NetGuardBase.fromDio(Dio dio) {
    _dio = dio;
    options = NetGuardOptions.fromBaseOptions(_dio.options);
    interceptors = NetGuardInterceptors(_dio.interceptors);

    // Set up the callback for when network handling is enabled
    options.setNetworkHandlingCallback(() async {
      await _initializeNetworkHandling();
    });
  }

  /// Initialize network service immediately (non-blocking)
  void _initializeNetworkServiceEarly() {
    // Initialize network service in the background
    NetworkService.instance.initialize(3).then((success) {
      if (success) {
        print('🌐 Network service auto-initialized successfully');
      } else {
        print('❌ Network service auto-initialization failed: ${NetworkService.instance.initializationError}');
      }
    }).catchError((error) {
      print('❌ Network service auto-initialization error: $error');
    });
  }

  /// Get the underlying Dio instance
  Dio get dio => _dio;

  /// Close the NetGuard instance and clean up resources
  void close({bool force = false}) {
    _dio.close(force: force);
  }

  /// Initialize network handling if enabled
  Future<void> _initializeNetworkHandling() async {
    if (!options.handleNetwork || _networkInitialized) return;

    print('🌐 Initializing network handling...');

    try {
      // Wait for network service to be initialized (should already be initializing)
      bool success = NetworkService.instance.isInitialized;
      if (!success) {
        success = await NetworkService.instance.initialize(4);
      }

      if (!success) {
        print('❌ Network service initialization failed: ${NetworkService.instance.initializationError}');
        return;
      }

      // Add network interceptor if not already added
      if (!_networkInterceptorAdded) {
        _dio.interceptors.insert(0, NetworkInterceptor()); // Insert at beginning for priority
        _networkInterceptorAdded = true;
        print('📡 Network interceptor added');
      }

      _networkInitialized = true;
      print('✅ Network handling initialized successfully');
    } catch (e) {
      print('❌ Network handling initialization failed: $e');
    }
  }

  /// Add network extras to options for all requests
  Options _addNetworkExtras(Options? options) {
    final extras = <String, dynamic>{
      'handleNetwork': this.options.handleNetwork,
      'autoRetryOnNetworkRestore': this.options.autoRetryOnNetworkRestore,
      'maxNetworkRetries': this.options.maxNetworkRetries,
      'throwOnOffline': this.options.throwOnOffline,
    };

    if (options == null) {
      return Options(extra: extras);
    }

    return options.copyWith(
      extra: {...options.extra ?? {}, ...extras},
    );
  }

  /// Get current network status
  NetworkStatus get networkStatus => NetworkService.instance.currentStatus;

  /// Check if network is online
  bool get isNetworkOnline => NetworkService.instance.isOnline;

  /// Check if currently online (alias for consistency)
  bool get isOnline => NetworkService.instance.isOnline;

  /// Check if currently offline
  bool get isOffline => NetworkService.instance.isOffline;

  /// Get network connection info
  Map<String, dynamic> get networkInfo => NetworkService.instance.getConnectionInfo();

  /// Stream of network status changes - Available immediately without manual initialization
  Stream<NetworkStatus> get statusStream => NetworkService.instance.statusStream;

  /// Manually refresh network status
  Future<void> refreshNetworkStatus() async {
    await NetworkService.instance.refresh();
  }

  /// Convenience method to make a GET request
  Future<Response<T>> get<T>(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
        bool encryptBody = false,
        bool useCache = false,
      }) async {

    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options ??= Options();
      options.contentType = options.contentType ?? Headers.textPlainContentType;
    }

    // Add network extras to options
    options = _addNetworkExtras(options);

    if (useCache) {
      final cached = await CacheManager.getResponse(
        options: this.options,
        path: path,
        query: queryParameters,
      );

      // Start background fetch (non-blocking)
      unawaited(() async {
        try {
          final newResponse = await _dio.get<T>(
            path,
            data: encryptBody ? encrypted : data,
            queryParameters: queryParameters,
            options: options,
            cancelToken: cancelToken,
            onReceiveProgress: onReceiveProgress,
          );
          if (newResponse.statusCode == 200) {
            await CacheManager.saveResponse(
              options: this.options,
              path: path,
              query: queryParameters,
              response: newResponse.data,
            );
          }
        } catch (e) {
          print("fetch error $e");
        }
      }());

      if (cached != null) {
        return Response<T>(
          data: cached as T,
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
        );
      }
    }

    final response = await _dio.get<T>(
      path,
      data: encryptBody ? encrypted : data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );

    if (useCache && response.statusCode == 200) {
      await CacheManager.saveResponse(
        options: this.options,
        path: path,
        query: queryParameters,
        response: response.data,
      );
    }

    return response;
  }

  /// Convenience method to make a GET request and return URI
  Future<Response> getUri(
      String path, {
        Map<String, dynamic>? queryParameters,
      }) {
    return _dio.getUri(Uri.parse(path).replace(
      queryParameters: queryParameters,
    ));
  }

  /// Convenience method to make a POST request
  Future<Response<T>> post<T>(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        bool encryptBody = false,
      }) async {

    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options ??= Options();
      options.contentType = options.contentType ?? Headers.textPlainContentType;
    }

    // Add network extras to options
    options = _addNetworkExtras(options);

    return _dio.post<T>(
      path,
      data: encryptBody ? encrypted : data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Convenience method to make a PUT request
  Future<Response<T>> put<T>(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        bool encryptBody = false,
      }) async {


    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options ??= Options();
      options.contentType = options.contentType ?? Headers.textPlainContentType;
    }

    // Add network extras to options
    options = _addNetworkExtras(options);

    return _dio.put<T>(
      path,
      data: encryptBody ? encrypted : data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Convenience method to make a PATCH request
  Future<Response<T>> patch<T>(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        bool encryptBody = false,
      }) async {

    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options ??= Options();
      options.contentType = options.contentType ?? Headers.textPlainContentType;
    }

    // Add network extras to options
    options = _addNetworkExtras(options);

    return _dio.patch<T>(
      path,
      data: encryptBody ? encrypted : data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Convenience method to make a DELETE request
  Future<Response<T>> delete<T>(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        bool encryptBody = false,
      }) async {

    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options ??= Options();
      options.contentType = options.contentType ?? Headers.textPlainContentType;
    }

    // Add network extras to options
    options = _addNetworkExtras(options);

    return _dio.delete<T>(
      path,
      data: encryptBody ? encrypted : data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Convenience method to make a HEAD request
  Future<Response<T>> head<T>(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        bool encryptBody = false,
      }) async {

    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options ??= Options();
      options.contentType = options.contentType ?? Headers.textPlainContentType;
    }

    // Add network extras to options
    options = _addNetworkExtras(options);

    return _dio.head<T>(
      path,
      data: encryptBody ? encrypted : data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Make HTTP request with options
  Future<Response<T>> request<T>(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        Options? options,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        bool encryptBody = false,
        bool useCache = false,
      }) async {

    final method = (options?.method ?? 'get').toLowerCase();

    // Add network extras to options
    options = _addNetworkExtras(options);

    // Cache support only for GET
    if (method == 'get' && useCache) {
      final cached = await CacheManager.getResponse(
        options: this.options,
        path: path,
        query: queryParameters,
      );

      // Start background refresh
      unawaited(() async {
        try {
          String encrypted = '';
          if (encryptBody) {
            encrypted = this.options.encryptionFunction(data);
          }

          final freshResponse = await _dio.request<T>(
            path,
            data: encryptBody ? encrypted : data,
            queryParameters: queryParameters,
            cancelToken: cancelToken,
            options: options,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );

          if (freshResponse.statusCode == 200) {
            await CacheManager.saveResponse(
              options: this.options,
              path: path,
              query: queryParameters,
              response: freshResponse.data,
            );
          }
        } catch (_) {
          // silently fail
        }
      }());

      // Return cached immediately if available
      if (cached != null) {
        return Response<T>(
          data: cached as T,
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
        );
      }
    }

    // Encrypt if required
    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options ??= Options();
      options.contentType = options.contentType ?? Headers.textPlainContentType;
    }

    // Perform actual request
    final response = await _dio.request<T>(
      path,
      data: encryptBody ? encrypted : data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    // Save fresh response to cache if it's GET
    if (method == 'get' && useCache && response.statusCode == 200) {
      await CacheManager.saveResponse(
        options: this.options,
        path: path,
        query: queryParameters,
        response: response.data,
      );
    }

    return response;
  }

  /// Make HTTP request with URI
  Future<Response<T>> requestUri<T>(
      Uri uri, {
        Object? data,
        CancelToken? cancelToken,
        Options? options,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        bool encryptBody = false,
      }) async {

    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options ??= Options();
      options.contentType = options.contentType ?? Headers.textPlainContentType;
    }

    // Add network extras to options
    options = _addNetworkExtras(options);

    return _dio.requestUri<T>(
      uri,
      data: encryptBody ? encrypted : data,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Download file
  Future<Response> download(
      String urlPath,
      dynamic savePath, {
        ProgressCallback? onReceiveProgress,
        Map<String, dynamic>? queryParameters,
        CancelToken? cancelToken,
        bool deleteOnError = true,
        String lengthHeader = Headers.contentLengthHeader,
        Object? data,
        Options? options,
        bool encryptBody = false,
      }) async {


    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options ??= Options();
      options.contentType = options.contentType ?? Headers.textPlainContentType;
    }

    // Add network extras to options
    options = _addNetworkExtras(options);

    return _dio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      data: encryptBody ? encrypted : data,
      options: options,
    );
  }

  /// Download file with URI
  Future<Response> downloadUri(
      Uri uri,
      dynamic savePath, {
        ProgressCallback? onReceiveProgress,
        CancelToken? cancelToken,
        bool deleteOnError = true,
        String lengthHeader = Headers.contentLengthHeader,
        Object? data,
        Options? options,
        bool encryptBody = false,
      }) async {


    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options ??= Options();
      options.contentType = options.contentType ?? Headers.textPlainContentType;
    }

    // Add network extras to options
    options = _addNetworkExtras(options);

    return _dio.downloadUri(
      uri,
      savePath,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      data: encryptBody ? encrypted : data,
      options: options,
    );
  }

  /// Fetch data with options
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) {
    return _dio.fetch<T>(requestOptions);
  }
}