import 'package:dio/dio.dart';

/// NetGuard error wrapper (currently just re-exports Dio exceptions)
/// This allows for future enhancements without breaking changes
typedef NetGuardError = DioException;
typedef NetGuardErrorType = DioExceptionType;

/// NetGuard error extension methods
extension NetGuardErrorExtension on DioException {
  /// Check if error is a connection timeout
  bool get isConnectionTimeout {
    return type == DioExceptionType.connectionTimeout;
  }

  /// Check if error is a send timeout
  bool get isSendTimeout {
    return type == DioExceptionType.sendTimeout;
  }

  /// Check if error is a receive timeout
  bool get isReceiveTimeout {
    return type == DioExceptionType.receiveTimeout;
  }

  /// Check if error is a bad certificate
  bool get isBadCertificate {
    return type == DioExceptionType.badCertificate;
  }

  /// Check if error is a bad response
  bool get isBadResponse {
    return type == DioExceptionType.badResponse;
  }

  /// Check if error is a cancel
  bool get isCancelled {
    return type == DioExceptionType.cancel;
  }

  /// Check if error is a connection error
  bool get isConnectionError {
    return type == DioExceptionType.connectionError;
  }

  /// Check if error is unknown
  bool get isUnknown {
    return type == DioExceptionType.unknown;
  }

  /// Get error status code
  int? get statusCode {
    return response?.statusCode;
  }

  /// Get error status message
  String? get statusMessage {
    return response?.statusMessage;
  }

  /// Check if error is a network error (no internet connection)
  bool get isNetworkError {
    return isConnectionError || isConnectionTimeout;
  }

  /// Check if error is a timeout error
  bool get isTimeoutError {
    return isConnectionTimeout || isSendTimeout || isReceiveTimeout;
  }

  /// Check if error is a client error (4xx status codes)
  bool get isClientError {
    final code = statusCode;
    return code != null && code >= 400 && code < 500;
  }

  /// Check if error is a server error (5xx status codes)
  bool get isServerError {
    final code = statusCode;
    return code != null && code >= 500 && code < 600;
  }

  /// Get a user-friendly error message
  String get userFriendlyMessage {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection and try again.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. The server is taking too long to respond.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. The server is taking too long to respond.';
      case DioExceptionType.badCertificate:
        return 'Security certificate error. Unable to verify server identity.';
      case DioExceptionType.badResponse:
        if (isClientError) {
          return 'Client error: ${statusMessage ?? 'Bad request'}';
        } else if (isServerError) {
          return 'Server error: ${statusMessage ?? 'Internal server error'}';
        }
        return 'Bad response from server: ${statusMessage ?? 'Unknown error'}';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.unknown:
        return 'An unknown error occurred: ${message ?? 'Unknown error'}';
    }
  }
}