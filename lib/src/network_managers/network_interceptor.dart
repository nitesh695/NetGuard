import 'dart:async';
import 'package:dio/dio.dart';
import 'package:netguard/netguard.dart';

import 'network_exception.dart';


class NetworkInterceptor extends Interceptor {
  final NetworkService _networkService = NetworkService.instance;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Check if network handling is enabled
    final handleNetwork = options.extra['handleNetwork'] as bool? ?? false;
    if (!handleNetwork) {
      return handler.next(options);
    }

    // Initialize network service if not already done
    if (!_networkService.isInitialized) {
      await _networkService.initialize(2);
    }

    // Check network status
    if (_networkService.isOffline) {
      final throwOnOffline = options.extra['throwOnOffline'] as bool? ?? false;

      if (throwOnOffline) {
        // Immediately throw exception
        return handler.reject(NetworkOfflineException(requestOptions: options));
      } else {
        // Wait for network to come back online
        await _waitForNetwork(options);
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if this is a network-related error and auto-retry is enabled
    final handleNetwork = err.requestOptions.extra['handleNetwork'] as bool? ?? false;
    final autoRetry = err.requestOptions.extra['autoRetryOnNetworkRestore'] as bool? ?? true;

    if (handleNetwork && autoRetry && _isNetworkError(err)) {
      final maxRetries = err.requestOptions.extra['maxNetworkRetries'] as int? ?? 3;
      final currentRetry = err.requestOptions.extra['currentNetworkRetry'] as int? ?? 0;

      if (currentRetry < maxRetries) {
        print('🔄 Network error detected, attempting retry ${currentRetry + 1}/$maxRetries');

        // Wait for network to be restored
        await _waitForNetwork(err.requestOptions);

        // Update retry count
        err.requestOptions.extra['currentNetworkRetry'] = currentRetry + 1;

        // Retry the request
        try {
          final dio = Dio();
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // If retry fails, continue with original error handling
        }
      }
    }

    handler.next(err);
  }

  /// Wait for network to come back online
  Future<void> _waitForNetwork(RequestOptions options) async {
    if (_networkService.isOnline) return;

    print('⏳ Waiting for network connection...');

    final completer = Completer<void>();
    late StreamSubscription subscription;

    // Set up timeout
    final timeout = Timer(const Duration(minutes: 2), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(NetworkOfflineException(requestOptions: options));
      }
    });

    // Listen for network status changes
    subscription = _networkService.statusStream.listen((status) {
      if (status == NetworkStatus.online && !completer.isCompleted) {
        timeout.cancel();
        subscription.cancel();
        completer.complete();
        print('✅ Network connection restored');
      }
    });

    // If already online, complete immediately
    if (_networkService.isOnline) {
      timeout.cancel();
      subscription.cancel();
      completer.complete();
    }

    return completer.future;
  }

  /// Check if error is network-related
  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;
  }
}