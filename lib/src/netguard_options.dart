import 'dart:convert';
import 'package:dio/dio.dart';

class NetGuardOptions {
  late final BaseOptions _baseOptions;

  /// Function to encrypt/encode the request body
  late String Function(dynamic body) encryptionFunction;

  /// Default body encryption function using jsonEncode
  static String _defaultEncryptionFunction(dynamic body) {
    return jsonEncode(body);
  }

  /// Cache duration for Hive cache expiration
  Duration? cacheDuration;

  /// Max cache size (number of entries)
  int? maxCacheSize;

  /// Enable automatic network connectivity handling
  bool _handleNetwork = false;

  /// Automatically retry requests when network comes back online
  bool autoRetryOnNetworkRestore = true;

  /// Maximum number of auto-retry attempts
  int maxNetworkRetries = 3;

  /// Delay between retry attempts
  Duration networkRetryDelay = const Duration(seconds: 2);

  /// Throw exception when network is offline instead of waiting
  bool throwOnOffline = false;

  /// Callback to trigger network initialization
  Future<void> Function()? _onNetworkHandlingEnabled;

  /// Create NetGuard options from BaseOptions
  NetGuardOptions.fromBaseOptions(
      this._baseOptions, {
        String Function(dynamic body)? encryptionFunction,
      }) {
    this.encryptionFunction = encryptionFunction ?? _defaultEncryptionFunction;
  }

  /// Create NetGuard options with parameters
  NetGuardOptions({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
    bool? persistentConnection,
    String Function(dynamic body)? encryptionFunction,
    Duration? cacheDuration,
    int? maxCacheSize,
  }) {
    _baseOptions = BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: headers,
      extra: extra,
      responseType: responseType,
      contentType: contentType,
      validateStatus: validateStatus,
      receiveDataWhenStatusError: receiveDataWhenStatusError,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      requestEncoder: requestEncoder,
      responseDecoder: responseDecoder,
      listFormat: listFormat,
      persistentConnection: persistentConnection,
    );

    this.encryptionFunction = encryptionFunction ?? _defaultEncryptionFunction;
    this.cacheDuration = cacheDuration ?? const Duration(minutes: 5);
    this.maxCacheSize = maxCacheSize ?? 100;
  }

  /// Set the callback for network handling enablement
  void setNetworkHandlingCallback(Future<void> Function() callback) {
    _onNetworkHandlingEnabled = callback;
  }

  /// Handle network property getter/setter
  bool get handleNetwork => _handleNetwork;

  set handleNetwork(bool value) {
    if (value && !_handleNetwork) {
      // Network handling is being enabled, trigger initialization asynchronously
      _handleNetwork = value;
      if (_onNetworkHandlingEnabled != null) {
        // Don't await here to avoid blocking the setter
        _onNetworkHandlingEnabled!().catchError((error) {
          print('❌ Network handling initialization failed: $error');
        });
      }
    } else {
      _handleNetwork = value;
    }
  }

  /// Base URL for requests
  String? get baseUrl => _baseOptions.baseUrl;
  set baseUrl(String? value) => _baseOptions.baseUrl = value!;

  /// Timeout for opening connections
  Duration? get connectTimeout => _baseOptions.connectTimeout;
  set connectTimeout(Duration? value) => _baseOptions.connectTimeout = value;

  /// Timeout for receiving data
  Duration? get receiveTimeout => _baseOptions.receiveTimeout;
  set receiveTimeout(Duration? value) => _baseOptions.receiveTimeout = value;

  /// Timeout for sending data
  Duration? get sendTimeout => _baseOptions.sendTimeout;
  set sendTimeout(Duration? value) => _baseOptions.sendTimeout = value;

  /// Default headers
  Map<String, dynamic> get headers => _baseOptions.headers;
  set headers(Map<String, dynamic> value) => _baseOptions.headers = value;

  /// Extra data
  Map<String, dynamic> get extra => _baseOptions.extra;
  set extra(Map<String, dynamic> value) => _baseOptions.extra = value;

  /// Response type
  ResponseType get responseType => _baseOptions.responseType;
  set responseType(ResponseType value) => _baseOptions.responseType = value;

  /// Content type
  String? get contentType => _baseOptions.contentType;
  set contentType(String? value) => _baseOptions.contentType = value;

  /// Validate status function
  ValidateStatus? get validateStatus => _baseOptions.validateStatus;
  set validateStatus(ValidateStatus? value) => _baseOptions.validateStatus = value!;

  /// Whether to receive data when status error
  bool get receiveDataWhenStatusError => _baseOptions.receiveDataWhenStatusError;
  set receiveDataWhenStatusError(bool value) => _baseOptions.receiveDataWhenStatusError = value;

  /// Whether to follow redirects
  bool get followRedirects => _baseOptions.followRedirects;
  set followRedirects(bool value) => _baseOptions.followRedirects = value;

  /// Maximum redirects
  int get maxRedirects => _baseOptions.maxRedirects;
  set maxRedirects(int value) => _baseOptions.maxRedirects = value;

  /// Request encoder
  RequestEncoder? get requestEncoder => _baseOptions.requestEncoder;
  set requestEncoder(RequestEncoder? value) => _baseOptions.requestEncoder = value;

  /// Response decoder
  ResponseDecoder? get responseDecoder => _baseOptions.responseDecoder;
  set responseDecoder(ResponseDecoder? value) => _baseOptions.responseDecoder = value;

  /// List format
  ListFormat get listFormat => _baseOptions.listFormat;
  set listFormat(ListFormat value) => _baseOptions.listFormat = value;

  /// Persistent connection
  bool get persistentConnection => _baseOptions.persistentConnection;
  set persistentConnection(bool value) => _baseOptions.persistentConnection = value;

  /// Get the underlying BaseOptions
  BaseOptions get baseOptions => _baseOptions;

  /// Copy with new values
  NetGuardOptions copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
    bool? persistentConnection,
    Duration? cacheDuration,
    int? maxCacheSize,
    String Function(dynamic body)? encryptionFunction,
    bool? handleNetwork,
    bool? autoRetryOnNetworkRestore,
    int? maxNetworkRetries,
    Duration? networkRetryDelay,
    bool? throwOnOffline,
  }) {
    return NetGuardOptions(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      headers: headers ?? Map<String, dynamic>.from(this.headers),
      extra: extra ?? Map<String, dynamic>.from(this.extra),
      responseType: responseType ?? this.responseType,
      contentType: contentType ?? this.contentType,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError: receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      requestEncoder: requestEncoder ?? this.requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
      listFormat: listFormat ?? this.listFormat,
      persistentConnection: persistentConnection ?? this.persistentConnection,
      encryptionFunction: encryptionFunction ?? this.encryptionFunction,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
    )..handleNetwork = handleNetwork ?? this.handleNetwork
      ..autoRetryOnNetworkRestore = autoRetryOnNetworkRestore ?? this.autoRetryOnNetworkRestore
      ..maxNetworkRetries = maxNetworkRetries ?? this.maxNetworkRetries
      ..networkRetryDelay = networkRetryDelay ?? this.networkRetryDelay
      ..throwOnOffline = throwOnOffline ?? this.throwOnOffline;
  }

  @override
  String toString() {
    return _baseOptions.toString();
  }
}