library netguard;

export 'src/netguard.dart';
export 'src/netguard_base.dart';
export 'src/netguard_options.dart';
export 'src/netguard_interceptors.dart';
export 'src/netguard_response.dart';
export 'src/netguard_error.dart';
export 'src/cache_manager.dart';
export 'src/network_managers/network_service.dart';

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