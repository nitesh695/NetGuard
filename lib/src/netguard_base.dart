import 'dart:async';
import 'package:dio/dio.dart';
import 'package:netguard/src/utils/util.dart';
import 'cache_manager.dart';
import 'models/queued_request.model.dart';
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

  /// Queue for offline requests
  final List<QueuedRequest> _requestQueue = [];
  StreamSubscription<NetworkStatus>? _networkStatusSubscription;

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
    _setupNetworkListener();
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
    _setupNetworkListener();
  }

  /// Setup network status listener
  void _setupNetworkListener() {
    _networkStatusSubscription = statusStream.listen((status) {
      if (status == NetworkStatus.online) {
        _processQueuedRequests();
      }
    });
  }

  /// Process queued requests when network comes back online
  Future<void> _processQueuedRequests() async {
    if (_requestQueue.isEmpty) return;

    logger('🔄 Processing ${_requestQueue.length} queued requests...');

    final queueCopy = List<QueuedRequest>.from(_requestQueue);
    _requestQueue.clear();

    for (final queuedRequest in queueCopy) {
      try {
        // Check if the request is still valid (not cancelled and not too old)
        if (queuedRequest.cancelToken?.isCancelled == true) {
          queuedRequest.completer.completeError(
            DioException(
              requestOptions: RequestOptions(path: queuedRequest.path),
              error: 'Request was cancelled',
              type: DioExceptionType.cancel,
            ),
          );
          continue;
        }

        // Execute the queued request
        final response = await _executeGetRequest(
          queuedRequest.path,
          data: queuedRequest.data,
          queryParameters: queuedRequest.queryParameters,
          options: queuedRequest.options,
          cancelToken: queuedRequest.cancelToken,
          onReceiveProgress: queuedRequest.onReceiveProgress,
          encryptBody: queuedRequest.encryptBody,
          useCache: queuedRequest.useCache,
          isFromQueue: true,
        );


        queuedRequest.completer.complete(response);
      } catch (e) {
        queuedRequest.completer.completeError(e);
      }
    }

    logger('✅ Processed all queued requests');
  }

  /// Create a network error response
  Future<Response<T>> _createNetworkErrorResponse<T>(String path) async{
    final Map<String, dynamic> responseData = {
      'statusCode': 503,
      'message': 'No Internet !',
    };

    return Response<T>(
      statusCode: 503,
      statusMessage: 'No Internet !',
      data: responseData as T, // Casting Map to generic T
      requestOptions: RequestOptions(path: path),
      extra: {
        'networkError': true,
        'message': 'No Internet !',
        'queued': true,
      },
    );
  }


  /// Execute the actual GET request
  Future<Response<T>> _executeGetRequest<T>(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
        bool encryptBody = false,
        bool useCache = false,
        bool isFromQueue = false,
      }) async
  {
    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options ??= Options();
      options.contentType = options.contentType ?? Headers.textPlainContentType;
    }

    // Add network extras to options
    options = _addNetworkExtras(options);

    if (useCache && !isFromQueue) {
      final cached = await CacheManager.getResponse(
        options: this.options,
        path: path,
        query: queryParameters,
      );

      // Start background fetch (non-blocking) only if online
      if (isNetworkOnline) {
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
            logger("Background fetch error: $e");
          }
        }());
      }

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

  /// Get the underlying Dio instance
  Dio get dio => _dio;

  /// Initialize network handling if enabled
  Future<void> _initializeNetworkHandling() async {
    if (!options.handleNetwork || _networkInitialized) return;

    logger('🌐 Initializing network handling...');

    try {
      // Wait for network service to be initialized (should already be initializing)
      bool success = NetworkService.instance.isInitialized;
      if (!success) {
        success = await NetworkService.instance.initialize();
      }

      if (!success) {
        logger('❌ Network service initialization failed: ${NetworkService.instance.initializationError}');
        return;
      }

      // Add network interceptor if not already added
      if (!_networkInterceptorAdded) {
        _dio.interceptors.insert(0, NetworkInterceptor()); // Insert at beginning for priority
        _networkInterceptorAdded = true;
        logger('📡 Network interceptor added');
      }

      _networkInitialized = true;
      logger('✅ Network handling initialized successfully');
    } catch (e) {
      logger('❌ Network handling initialization failed: $e');
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
      return Options(
        extra: extras,
        validateStatus: (status) => status != null && status < 600, // Accept 5xx as valid responses
      );
    }

    return options.copyWith(
      extra: {...options.extra ?? {}, ...extras},
      validateStatus: options.validateStatus ?? (status) => status != null && status < 600, // Only set if not already defined
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
      }) async
  {

    // Check network handling is enabled
    if (this.options.handleNetwork) {
      logger("Network handling enabled. Online status: $isNetworkOnline");

      // If network is offline
      if (!isNetworkOnline) {
        logger("📱 Network is offline, checking cache...");

        // Try to get from cache first
        if (useCache) {
          final cached = await CacheManager.getResponse(
            options: this.options,
            path: path,
            query: queryParameters,
          );

          if (cached != null) {
            logger("💾 Returning cached response");
            return Response<T>(
              data: cached as T,
              statusCode: 200,
              requestOptions: RequestOptions(path: path),
              extra: {'fromCache': true},
            );
          }
        }

        // No cache available, queue the request and return network error response
        logger("📋 Queueing request for when network comes online...");

        final completer = Completer<Response<T>>();
        final queuedRequest = QueuedRequest(
          path: path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
          encryptBody: encryptBody,
          useCache: useCache,
          completer: completer,
          timestamp: DateTime.now(),
        );

        _requestQueue.add(queuedRequest);

        // Return network error response immediately
        return _createNetworkErrorResponse<T>(path);
      }
    }

    // Network is online or network handling is disabled, proceed normally
    return await _executeGetRequest<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      encryptBody: encryptBody,
      useCache: useCache,
    );
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

    if (this.options.handleNetwork) {
      if (!isNetworkOnline) {
        return _createNetworkErrorResponse<T>(path);
      }
    }



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

    if (this.options.handleNetwork) {
      if (!isNetworkOnline) {
        return _createNetworkErrorResponse<T>(path);
      }
    }

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

    if (this.options.handleNetwork) {
      if (!isNetworkOnline) {
        return _createNetworkErrorResponse<T>(path);
      }
    }
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

    if (this.options.handleNetwork) {
      if (!isNetworkOnline) {
        return _createNetworkErrorResponse<T>(path);
      }
    }
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

    if (this.options.handleNetwork) {
      if (!isNetworkOnline) {
        return _createNetworkErrorResponse<T>(path);
      }
    }

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
    // Normalize method
    final method = (options?.method ?? 'get').toLowerCase();

    // Handle offline mode for GET with queue support
    if (this.options.handleNetwork && !isNetworkOnline && method == 'get') {
      logger("📱 Network is offline, checking cache...");

      // Try to get cached response
      if (useCache) {
        final cached = await CacheManager.getResponse(
          options: this.options,
          path: path,
          query: queryParameters,
        );

        if (cached != null) {
          logger("💾 Returning cached response");
          return Response<T>(
            data: cached as T,
            statusCode: 200,
            requestOptions: RequestOptions(path: path),
            extra: {'fromCache': true},
          );
        }
      }

      // No cache: queue request and return network error response
      logger("📋 Queueing GET request for when network comes online...");

      final completer = Completer<Response<T>>();
      final queuedRequest = QueuedRequest(
        path: path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        encryptBody: encryptBody,
        useCache: useCache,
        completer: completer,
        timestamp: DateTime.now(),
      );

      _requestQueue.add(queuedRequest);

      // Return simulated offline response
      return Future.value(_createNetworkErrorResponse<T>(path));
    }

    if(method != 'get' && this.options.handleNetwork && !isNetworkOnline){
      return Future.value(_createNetworkErrorResponse<T>(path));
    }

    // Add internal metadata to options
    options = _addNetworkExtras(options);

    // Handle GET caching
    if (method == 'get' && useCache) {
      final cached = await CacheManager.getResponse(
        options: this.options,
        path: path,
        query: queryParameters,
      );

      // Trigger background refresh
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
          // silent fail
        }
      }());

      // Return cached if found
      if (cached != null) {
        return Response<T>(
          data: cached as T,
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
          extra: {'fromCache': true},
        );
      }
    }

    // Handle encryption if needed
    String encrypted = '';
    if (encryptBody) {
      encrypted = this.options.encryptionFunction(data);
      options.contentType ??= Headers.textPlainContentType;
    }

    // Make the actual request
    final response = await _dio.request<T>(
      path,
      data: encryptBody ? encrypted : data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    // Cache the GET response if required
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

    if (this.options.handleNetwork) {
      if (!isNetworkOnline) {
        return _createNetworkErrorResponse<T>(uri.path);
      }
    }
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

  /// Close the NetGuard instance and clean up resources
  void close({bool force = false}) {
    _networkStatusSubscription?.cancel();

    // Complete any pending queued requests with cancellation error
    for (final queuedRequest in _requestQueue) {
      if (!queuedRequest.completer.isCompleted) {
        queuedRequest.completer.completeError(
          DioException(
            requestOptions: RequestOptions(path: queuedRequest.path),
            error: 'NetGuard instance was closed',
            type: DioExceptionType.cancel,
          ),
        );
      }
    }
    _requestQueue.clear();

    _dio.close(force: force);
  }

  /// Get queued requests count
  int get queuedRequestsCount => _requestQueue.length;

  /// Clear queued requests (useful for testing or manual cleanup)
  void clearQueue() {
    for (final queuedRequest in _requestQueue) {
      if (!queuedRequest.completer.isCompleted) {
        queuedRequest.completer.completeError(
          DioException(
            requestOptions: RequestOptions(path: queuedRequest.path),
            error: 'Queue was manually cleared',
            type: DioExceptionType.cancel,
          ),
        );
      }
    }
    _requestQueue.clear();
  }
}