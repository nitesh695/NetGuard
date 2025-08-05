import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'netguard_options.dart';
import 'netguard_interceptors.dart';

/// Base class for NetGuard that provides all Dio functionality
abstract class NetGuardBase {
  /// The underlying Dio instance
  late final Dio _dio;

  /// NetGuard options that extend Dio's BaseOptions
  late NetGuardOptions options;

  /// Interceptors for NetGuard
  late NetGuardInterceptors interceptors;

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
  }

  /// Initialize NetGuard from existing Dio instance
  NetGuardBase.fromDio(Dio dio) {
    _dio = dio;
    options = NetGuardOptions.fromBaseOptions(_dio.options);
    interceptors = NetGuardInterceptors(_dio.interceptors);
  }

  /// Get the underlying Dio instance
  Dio get dio => _dio;

  /// Close the NetGuard instance and clean up resources
  void close({bool force = false}) {
    _dio.close(force: force);
  }

  // HTTP Methods

  /// Convenience method to make a GET request
  Future<Response<T>> get<T>(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
      }) {
    return _dio.get<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
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
      }) {
    return _dio.post<T>(
      path,
      data: data,
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
      }) {
    return _dio.put<T>(
      path,
      data: data,
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
      }) {
    return _dio.patch<T>(
      path,
      data: data,
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
      }) {
    return _dio.delete<T>(
      path,
      data: data,
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
      }) {
    return _dio.head<T>(
      path,
      data: data,
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
      }) {
    return _dio.request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Make HTTP request with URI
  Future<Response<T>> requestUri<T>(
      Uri uri, {
        Object? data,
        CancelToken? cancelToken,
        Options? options,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) {
    return _dio.requestUri<T>(
      uri,
      data: data,
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
      }) {
    return _dio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      data: data,
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
      }) {
    return _dio.downloadUri(
      uri,
      savePath,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      data: data,
      options: options,
    );
  }

  /// Fetch data with options
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) {
    return _dio.fetch<T>(requestOptions);
  }
}