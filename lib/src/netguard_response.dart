import 'package:dio/dio.dart';

/// NetGuard response wrapper (currently just re-exports Dio Response)
/// This allows for future enhancements without breaking changes
typedef NetGuardResponse<T> = Response<T>;

/// NetGuard response extension methods
extension NetGuardResponseExtension<T> on Response<T> {
  /// Check if response is successful (status code 200-299)
  bool get isSuccessful {
    return statusCode != null && statusCode! >= 200 && statusCode! < 300;
  }

  /// Check if response is redirect (status code 300-399)
  bool get isRedirect {
    return statusCode != null && statusCode! >= 300 && statusCode! < 400;
  }

  /// Check if response is client error (status code 400-499)
  bool get isClientError {
    return statusCode != null && statusCode! >= 400 && statusCode! < 500;
  }

  /// Check if response is server error (status code 500-599)
  bool get isServerError {
    return statusCode != null && statusCode! >= 500 && statusCode! < 600;
  }

  // /// Get response status message
  // String get statusMessage {
  //   return statusMessage ?? 'Unknown';
  // }

  /// Get response content type
  String? get contentType {
    return headers.value('content-type');
  }

  /// Get response content length
  int? get contentLength {
    final lengthStr = headers.value('content-length');
    return lengthStr != null ? int.tryParse(lengthStr) : null;
  }

  /// Check if response has JSON content type
  bool get isJson {
    final type = contentType?.toLowerCase();
    return type != null && type.contains('application/json');
  }

  /// Check if response has XML content type
  bool get isXml {
    final type = contentType?.toLowerCase();
    return type != null && (type.contains('application/xml') || type.contains('text/xml'));
  }

  /// Check if response has HTML content type
  bool get isHtml {
    final type = contentType?.toLowerCase();
    return type != null && type.contains('text/html');
  }

  /// Check if response has plain text content type
  bool get isPlainText {
    final type = contentType?.toLowerCase();
    return type != null && type.contains('text/plain');
  }
}