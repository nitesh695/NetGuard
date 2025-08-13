import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../utils/util.dart';

enum NetworkStatus {
  online,
  offline,
  unknown,
}

class NetworkService {
  static NetworkService? _instance;
  static NetworkService get instance => _instance ??= NetworkService._();

  NetworkService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  NetworkStatus _currentStatus = NetworkStatus.unknown;
  final StreamController<NetworkStatus> _statusController = StreamController<NetworkStatus>.broadcast();

  bool _isInitialized = false;
  bool _isMonitoring = false;
  String? _initializationError;

  /// Current network status
  NetworkStatus get currentStatus => _currentStatus;

  /// Stream of network status changes
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Check if currently online
  bool get isOnline => _currentStatus == NetworkStatus.online;

  /// Check if currently offline
  bool get isOffline => _currentStatus == NetworkStatus.offline;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get initialization error if any
  String? get initializationError => _initializationError;

  /// Initialize network monitoring
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _initializationError = null;
      logger('🌐 Initializing NetworkService...');

      // Check initial connectivity
      await _checkConnectivity();

      // Start monitoring connectivity changes
      _startMonitoring();

      _isInitialized = true;
      logger('✅ NetworkService initialized - Status: $_currentStatus');
      return true;
    } catch (e) {
      _initializationError = e.toString();
      logger('❌ NetworkService initialization failed: $e');
      _currentStatus = NetworkStatus.unknown;
      _isInitialized = false;
      return false;
    }
  }

  /// Start monitoring network changes
  void _startMonitoring() {
    if (_isMonitoring) return;

    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
            (List<ConnectivityResult> results) async {
              logger('🔄 Connectivity changed: $results');
          await _updateConnectivityStatus(results);
        },
        onError: (error) {
          logger('❌ Network monitoring error: $error');
          _currentStatus = NetworkStatus.unknown;
          _statusController.add(_currentStatus);
        },
      );

      _isMonitoring = true;
      logger('📡 Network monitoring started');
    } catch (e) {
      logger('❌ Failed to start network monitoring: $e');
    }
  }

  /// Check current connectivity
  Future<void> _checkConnectivity() async {
    try {
      logger('🔍 Checking initial connectivity...');
      final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
      logger('📶 Connectivity results: $connectivityResults');
      await _updateConnectivityStatus(connectivityResults);
    } catch (e) {
      logger('❌ Connectivity check failed: $e');
      _currentStatus = NetworkStatus.unknown;
    }
  }

  /// Update connectivity status based on results
  Future<void> _updateConnectivityStatus(List<ConnectivityResult> results) async {
    final previousStatus = _currentStatus;

    // Check if any connection type indicates online status
    final hasConnection = results.any((result) =>
    result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);

    logger('📊 Has connection: $hasConnection');

    if (hasConnection) {
      // Verify actual internet connectivity with a ping test
      logger('🏓 Testing actual internet connectivity...');
      final actuallyOnline = await _performConnectivityTest();
      _currentStatus = actuallyOnline ? NetworkStatus.online : NetworkStatus.offline;
      logger('🎯 Internet test result: $actuallyOnline');
    } else {
      _currentStatus = NetworkStatus.offline;
      logger('📵 No network connection detected');
    }

    // Notify listeners if status changed
    if (previousStatus != _currentStatus) {
      logger('🔄 Network status changed: $previousStatus → $_currentStatus');
      _statusController.add(_currentStatus);
    }
  }

  /// Perform actual internet connectivity test
  Future<bool> _performConnectivityTest() async {
    try {
      // Try multiple endpoints for reliability
      final testEndpoints = [
        'https://www.google.com',
        'https://www.cloudflare.com',
        'https://httpbin.org/status/200',
      ];

      for (final endpoint in testEndpoints) {
        try {
          logger('🔗 Testing endpoint: $endpoint');
          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 10);

          final request = await client.getUrl(Uri.parse(endpoint));
          final response = await request.close();
          await response.drain(); // Consume the response
          client.close();

          logger('✅ Endpoint $endpoint responded with: ${response.statusCode}');
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return true;
          }
        } catch (e) {
          logger('❌ Endpoint $endpoint failed: $e');
          // Try next endpoint
          continue;
        }
      }

      return false;
    } catch (e) {
      logger('❌ Connectivity test failed: $e');
      return false;
    }
  }

  /// Manually refresh network status
  Future<void> refresh() async {
    logger('🔄 Manually refreshing network status...');
    await _checkConnectivity();
  }

  /// Stop monitoring network changes
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    _isMonitoring = false;
    _isInitialized = false;
    logger('🛑 NetworkService disposed');
  }

  /// Get network connection info
  Map<String, dynamic> getConnectionInfo() {
    return {
      'status': _currentStatus.toString().split('.').last,
      'isOnline': isOnline,
      'isOffline': isOffline,
      'isInitialized': _isInitialized,
      'isMonitoring': _isMonitoring,
      'initializationError': _initializationError,
    };
  }
}