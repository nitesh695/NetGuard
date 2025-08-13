library;

export 'src/netguard.dart';
export 'src/netguard_base.dart';
export 'src/netguard_options.dart';
export 'src/netguard_interceptors.dart';
export 'src/netguard_response.dart';
export 'src/netguard_error.dart';
export 'src/cache_manager.dart' ;
export 'src/network_managers/network_service.dart' show NetworkStatus;

// Add these new auth exports
export 'src/auth/auth_interceptor.dart';
export 'src/auth/auth_manager.dart';
export 'src/auth/advance_auth_callbacks.dart';

// Re-export Dio types for convenience
export 'package:dio/dio.dart' show
RequestOptions,
Response,
DioException,
DioExceptionType,
ResponseType,
ListFormat,
Headers,
FormData,
MultipartFile,
CancelToken,
ProgressCallback,
ValidateStatus,
ResponseDecoder,
RequestEncoder,
Transformer,
Options,
HttpClientAdapter,
Interceptor,
InterceptorsWrapper,
QueuedInterceptor,
QueuedInterceptorsWrapper;

export 'package:dio/io.dart' show IOHttpClientAdapter;