import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:netguard/netguard.dart';

void main() {
  runApp(const NetGuardExampleApp());
}

class NetGuardExampleApp extends StatelessWidget {
  const NetGuardExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetGuard Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const NetGuardExamplePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NetGuardExamplePage extends StatefulWidget {
  const NetGuardExamplePage({super.key});

  @override
  State<NetGuardExamplePage> createState() => _NetGuardExamplePageState();
}

class _NetGuardExamplePageState extends State<NetGuardExamplePage> {
  final NetGuard _netGuard = NetGuard();
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  bool _isLoading = false;
  String? _accessToken = 'demo_access_token_12345';

  @override
  void initState() {
    super.initState();
    _initializeNetGuard();
  }

  @override
  void dispose() {
    _netGuard.close();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize NetGuard with your exact configuration pattern
  Future<void> _initializeNetGuard() async {
    _addLog('🚀 Initializing NetGuard...');

    // Your exact initialization pattern
    _netGuard.options.baseUrl = 'https://jsonplaceholder.typicode.com';
    _netGuard.options.connectTimeout = const Duration(seconds: 10);
    _netGuard.options.receiveTimeout = const Duration(seconds: 10);
    _netGuard.options.sendTimeout = const Duration(seconds: 10);
    _netGuard.options.cacheDuration = const Duration(minutes: 10);

    _netGuard.options.maxCacheSize = 10;
    _netGuard.options.encryptionFunction = (body){
      final json = jsonEncode(body);
      return base64Encode(utf8.encode(json));
    };

    _netGuard.configureAuth(
      callbacks: AdvanceAuthCallbacks(
        initialToken: '123456sdfghjk',
        initialRefreshToken: 'asdfghjnbvcxsdfghj',
        onRefreshToken: _handleTokenRefresh,
        onTokenRefreshed: _handleTokenRefreshed,
        onLogout: _handleLogout,
      ),
      config: const AuthConfig(
        enableLogging: true, // Debug authentication
        maxRetryAttempts: 2,
        tokenHeaderName: 'Authorization',
        tokenPrefix: 'Bearer ',
      ),
    );

    ///network config.......
    _netGuard.options.handleNetwork = true;
    _netGuard.options.autoRetryOnNetworkRestore = true;
    _netGuard.options.maxNetworkRetries = 3;
    _netGuard.options.throwOnOffline = true;

    _netGuard.statusStream.listen((status) {
      // This works immediately - no manual initialization needed!
      if( status == NetworkStatus.online){
        print('🌐 Network status1111: ${status}');
      }
    });

    print('📊 Network info: ${_netGuard.refreshNetworkStatus()}');

    // Configure HTTP client adapter for certificate handling
    (_netGuard.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      client.idleTimeout = const Duration(seconds: 15);
      return client;
    };

    print("cache manager.....${CacheManager.getStats()}");
    // Add interceptors exactly as in your pattern
    _netGuard.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // if (_accessToken?.isNotEmpty == true) {
          //   options.headers['Authorization'] = 'Bearer $_accessToken';
          // }
          // _addLog('📤 ${options.method} ${options.uri}');

          print("header while req....${options.headers}");
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          print("header while req....${response.headers}");
          _addLog('✅ ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (e, handler) async {
          _addLog("❌ NetGuard error: ${e.message}");
          _closeAllActiveLoaders();
          return handler.next(e);
        },
      ),
    );

    _addLog('✅ NetGuard initialized successfully');
  }

  Future<String?> _handleTokenRefresh() async {
    _addLog('🔄 Refreshing token...');

    try {
      // Create a temporary NetGuard instance without auth for refresh call
      final refreshClient = NetGuard.withOptions(
        baseUrl: _netGuard.options.baseUrl,
      );

      final response = await refreshClient.post('/auth/refresh', data: {
        // 'refresh_token': _getStoredRefreshToken(),
      });

      if (response.statusCode == 200) {
        final newToken = response.data['access_token'];
        _addLog('✅ Token refresh successful');
        return newToken;
      }

      _addLog('❌ Token refresh failed: ${response.statusCode}');
      return null;
    } catch (e) {
      _addLog('❌ Token refresh error: $e');
      return null;
    }
  }

  /// Handle token refreshed
  Future<void> _handleTokenRefreshed(String newToken) async {
    _accessToken = newToken;
    // await _storeToken(newToken);
    _addLog('💾 New token stored');
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    _addLog('👋 User logged out');
    _accessToken = null;
    // await _clearStoredTokens();
    // Navigate to login screen
    // NavigationService.navigateToLogin();
  }


  /// Simulate closing active loaders (as mentioned in your pattern)
  void _closeAllActiveLoaders() {
    setState(() {
      _isLoading = false;
    });
    _addLog('🔄 All active loaders closed');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  /// Example API call using your exact pattern
  Future<void> _makeYourPatternApiCall() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('🔥 Making API call with your exact pattern...');

      // Your exact API call pattern
      final response = await _netGuard.post(
        '/posts', // Using posts endpoint as demo for your '/api/secure-data'
        encryptBody: true,
        data: {
          'sensitive_info': 'This will be encrypted',
          'user_id': 12345,
          'title': 'NetGuard Demo Post',
          'body': 'This is a test post created using NetGuard with your exact pattern',
        },
      );

      _addLog('📊 Response Data:');
      _addLog('   Status: ${response.statusCode}');
      _addLog('   Title: ${response.data['title']}');
      _addLog('   ID: ${response.data['id']}');
      _addLog('   User ID: ${response.data['userId']}');

    } catch (e) {
      _addLog('💥 Error occurred: $e');
      if (e is DioException) {
        _addLog('   Error Type: ${e.type}');
        _addLog('   User Message: ${e.userFriendlyMessage}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Example using static methods
  Future<void> _makeStaticApiCall() async {

    try {
      _addLog('⚡ Making static API call...');

      // Configure static instance
      NetGuard.configure(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        connectTimeout: const Duration(seconds: 15),
        headers: {
          'X-Static-Call': 'true',
          'Content-Type': 'application/json',
        },
      );

      // Use static method
      final response = await _netGuard.get('/users/4',encryptBody: false,useCache: true);

      print("response.....${response.data}");
      print("cache manager.....${CacheManager.getStats()}");
      if(response.statusCode == 200) {
        _addLog('📊 Static Response:');
        _addLog('   Name: ${response.data['name']}');
        _addLog('   Email: ${response.data['email']}');
        _addLog('   Website: ${response.data['website']}');
      }else{
        _addLog('📊 Static Response: ${response.data}');
      }


    } catch (e) {
      _addLog('💥 Static call error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  clearAllCaches()async{
    await CacheManager.clearAll();
  }

  /// Example demonstrating different HTTP methods
  Future<void> _demonstrateHttpMethods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('🔄 Demonstrating various HTTP methods...');

      // GET request
      final getResponse = await _netGuard.get('/posts/1',encryptBody: true,useCache: true);

      _addLog('GET: Retrieved post "${getResponse.data['title']}"');

      // POST request
      final postResponse = await _netGuard.post('/posts',
          encryptBody: true,
          data: {
            'title': 'NetGuard Test',
            'body': 'Testing NetGuard HTTP methods',
            'userId': 1,
          });
      _addLog('POST: Created post with ID ${postResponse.data['id']}');

      // PUT request
      final putResponse = await _netGuard.put('/posts/1',
          encryptBody: true,
          data: {
            'id': 1,
            'title': 'Updated via NetGuard PUT',
            'body': 'This post was updated using NetGuard PUT method',
            'userId': 1,
          });
      _addLog('PUT: Updated post "${putResponse.data['title']}"');

      // PATCH request
      final patchResponse = await _netGuard.patch('/posts/1',
          encryptBody: true,
          data: {
            'title': 'Patched via NetGuard',
          });
      _addLog('PATCH: Patched post "${patchResponse.data['title']}"');

      // DELETE request
      final deleteResponse = await _netGuard.delete('/posts/1',encryptBody: true,);
      _addLog('DELETE: Status ${deleteResponse.statusCode}');

    } catch (e) {
      _addLog('💥 HTTP methods demo error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Example demonstrating error handling
  Future<void> _demonstrateErrorHandling() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('🔍 Demonstrating error handling...');

      // This will cause a 404 error
      final response =await _netGuard.get('/nonexistent-endpoint',encryptBody: true,);
      _addLog('   Response: ${response.statusCode}....${response.data}');

    } catch (e) {
      if (e is DioException) {
        _addLog('❌ Caught DioException:');
        _addLog('   Type: ${e.type}');
        _addLog('   Status Code: ${e.statusCode}');
        _addLog('   Message: ${e.message}');
        _addLog('   User Friendly: ${e.userFriendlyMessage}');

        // Demonstrate error type checking
        if (e.isClientError) {
          _addLog('   → This is a client error (4xx)');
        } else if (e.isServerError) {
          _addLog('   → This is a server error (5xx)');
        } else if (e.isNetworkError) {
          _addLog('   → This is a network error');
        } else if (e.isTimeoutError) {
          _addLog('   → This is a timeout error');
        }
      } else {
        _addLog('❌ Other error: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NetGuard Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _makeYourPatternApiCall,
                        icon: const Icon(Icons.api),
                        label: const Text('Your Pattern'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _makeStaticApiCall,
                        icon: const Icon(Icons.bolt),
                        label: const Text('Static Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _demonstrateHttpMethods,
                        icon: const Icon(Icons.http),
                        label: const Text('HTTP Methods'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _demonstrateErrorHandling,
                    icon: const Icon(Icons.error_outline),
                    label: const Text('Error Handling Demo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: _isLoading ? Colors.orange.shade100 : Colors.green.shade100,
            child: Row(
              children: [
                if (_isLoading) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Text('Loading...', style: TextStyle(fontWeight: FontWeight.w500)),
                ] else ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  const Text('Ready', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
                const Spacer(),
                Text(
                  'Logs: ${_logs.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Logs Section
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        topRight: Radius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'NetGuard Logs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _logs.isEmpty
                        ? const Center(
                      child: Text(
                        'No logs yet. Try making an API call!',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                        : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color? logColor;
                        IconData? logIcon;

                        // Color code different types of logs
                        if (log.contains('❌')) {
                          logColor = Colors.red.shade700;
                          logIcon = Icons.error;
                        } else if (log.contains('✅')) {
                          logColor = Colors.green.shade700;
                          logIcon = Icons.check_circle;
                        } else if (log.contains('🚀') || log.contains('⚡') || log.contains('🔥')) {
                          logColor = Colors.blue.shade700;
                          logIcon = Icons.rocket_launch;
                        } else if (log.contains('📊')) {
                          logColor = Colors.purple.shade700;
                          logIcon = Icons.data_usage;
                        } else if (log.contains('🔄')) {
                          logColor = Colors.orange.shade700;
                          logIcon = Icons.refresh;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (logIcon != null) ...[
                                Icon(
                                  logIcon,
                                  size: 16,
                                  color: logColor,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: logColor ?? Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'NetGuard v1.0.0 - Built on top of Dio',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}