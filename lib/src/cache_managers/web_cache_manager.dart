import 'dart:convert';
import 'dart:html' as html;

import '../../netguard.dart';
import '../utils/util.dart';

class CacheManagerImpl {
  static const String _keyPrefix = 'netguard_cache_';
  static bool _isInitialized = false;
  static String? _initializationError;

  /// Initialize web cache (always succeeds unless localStorage is disabled)
  static Future<bool> initialize(NetGuardOptions options) async {
    try {
      _initializationError = null;

      // Test localStorage availability
      html.window.localStorage['netguard_test'] = 'test';
      html.window.localStorage.remove('netguard_test');

      _isInitialized = true;
      logger('✅ NetGuard Web Cache initialized successfully');
      return true;
    } catch (e) {
      _isInitialized = false;
      _initializationError = e.toString();
      logger('❌ NetGuard Web Cache Init Error: $e');
      return false;
    }
  }

  /// Auto-initialize if needed
  static Future<void> _initIfNeeded(NetGuardOptions options) async {
    if (!_isInitialized) {
      await initialize(options);
    }
  }

  /// Generate cache key from path and query parameters
  static String _generateKey(String path, Map<String, dynamic>? query) {
    final queryString = query != null ? jsonEncode(query) : '';
    return '$_keyPrefix${path}_$queryString';
  }

  /// Save response to cache
  static Future<void> saveResponse({
    required NetGuardOptions options,
    required String path,
    Map<String, dynamic>? query,
    required dynamic response,
  }) async {
    try {
      await _initIfNeeded(options);
      if (!_isInitialized) return;

      final key = _generateKey(path, query);
      final entry = {
        'data': response,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      html.window.localStorage[key] = jsonEncode(entry);
      await _enforceMaxSize(options);

      // print('💾 Web cached response for: $path');
    } catch (e) {
      print('❌ NetGuard Web Cache Save Error: $e');
    }
  }

  /// Get response from cache
  static Future<dynamic> getResponse({
    required NetGuardOptions options,
    required String path,
    Map<String, dynamic>? query,
  }) async {
    try {
      await _initIfNeeded(options);
      if (!_isInitialized) return null;

      final key = _generateKey(path, query);
      final cachedString = html.window.localStorage[key];
      if (cachedString == null) {
        print('🔍 Web cache miss for: $path');
        return null;
      }

      final cached = jsonDecode(cachedString);
      final expiry = options.cacheDuration ?? const Duration(minutes: 5);
      final timestamp = cached['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (age > expiry.inMilliseconds) {
        html.window.localStorage.remove(key);
        print('⏰ Web cache expired for: $path');
        return null;
      }

      print('🎯 Web cache hit for: $path');
      return cached['data'];
    } catch (e) {
      print('❌ NetGuard Web Cache Get Error: $e');
      return null;
    }
  }

  /// Enforce maximum cache size for web storage
  static Future<void> _enforceMaxSize(NetGuardOptions options) async {
    try {
      final maxSize = options.maxCacheSize ?? 100;
      final cacheKeys = html.window.localStorage.keys
          .where((key) => key.startsWith(_keyPrefix))
          .toList();

      if (cacheKeys.length <= maxSize) return;

      final entries = <String, Map<String, dynamic>>{};
      for (var key in cacheKeys) {
        final value = html.window.localStorage[key];
        if (value != null) {
          try {
            entries[key] = jsonDecode(value);
          } catch (e) {
            // Remove invalid entries
            html.window.localStorage.remove(key);
          }
        }
      }

      final sortedKeys = entries.entries.toList()
        ..sort((a, b) => (a.value['timestamp'] as int).compareTo(b.value['timestamp'] as int));

      final toRemove = sortedKeys.take(entries.length - maxSize);
      for (var entry in toRemove) {
        html.window.localStorage.remove(entry.key);
      }

      print('🧹 Web cache cleanup: removed ${toRemove.length} old entries');
    } catch (e) {
      print('❌ NetGuard Web Cache Size Enforcement Error: $e');
    }
  }

  /// Clear all cache entries
  static Future<void> clearAll() async {
    try {
      final keysToRemove = html.window.localStorage.keys
          .where((key) => key.startsWith(_keyPrefix))
          .toList();

      for (var key in keysToRemove) {
        html.window.localStorage.remove(key);
      }

      print('🗑️ Web cache cleared ${keysToRemove.length} entries');
    } catch (e) {
      print('❌ NetGuard Web Cache Clear All Error: $e');
    }
  }

  /// Check if cache is initialized
  static bool get isInitialized => _isInitialized;

  /// Get cache statistics
  static Map<String, dynamic> getStats() {
    final cacheKeys = html.window.localStorage.keys
        .where((key) => key.startsWith(_keyPrefix))
        .toList();

    return {
      'platform': 'web',
      'isInitialized': _isInitialized,
      'entryCount': cacheKeys.length,
      'storage': 'localStorage',
      'error': _initializationError,
    };
  }

  /// Get detailed initialization information
  static Map<String, dynamic> getInitializationInfo() {
    return {
      'isInitialized': _isInitialized,
      'initializationError': _initializationError,
      'platform': 'web',
      'storage': 'localStorage',
    };
  }
}