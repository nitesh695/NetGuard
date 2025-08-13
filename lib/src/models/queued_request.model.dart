import 'dart:async';
import '../../netguard.dart';


class QueuedRequest {
  final String path;
  final Object? data;
  final Map<String, dynamic>? queryParameters;
  final Options? options;
  final CancelToken? cancelToken;
  final ProgressCallback? onReceiveProgress;
  final bool encryptBody;
  final bool useCache;
  final Completer completer;
  final DateTime timestamp;

  QueuedRequest({
    required this.path,
    this.data,
    this.queryParameters,
    this.options,
    this.cancelToken,
    this.onReceiveProgress,
    required this.encryptBody,
    required this.useCache,
    required this.completer,
    required this.timestamp,
  });
}