import 'package:dio/dio.dart';

class NetworkOfflineException extends DioException {
  NetworkOfflineException({
    required super.requestOptions,
    super.response,
    super.type = DioExceptionType.connectionError,
    super.error,
  }) : super(
    message: 'No internet connection available. Please check your network settings and try again.',
  );

  @override
  String toString() {
    return 'NetworkOfflineException: No internet connection available';
  }
}