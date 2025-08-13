import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../netguard.dart';
import '../utils/util.dart';

class CacheManagerImpl {
  static const String _boxName = 'netguard_cache_box';
  static bool _isInitialized = false;
  static late Box _box;
  static String? _initializationError;
  static String? _cacheDirectory;

  /// Manually initialize the cache (returns success status)
  static Future<bool> initialize(NetGuardOptions options) async {
    if (_isInitialized) return true;

    try {
      _initializationError = null;

      // Get platform-specific directory
      Directory cacheDir;
      try {
        final appDir = await getTemporaryDirectory();
        cacheDir = Directory('${appDir.path}/netguard_cache');
        _cacheDirectory = cacheDir.path;
      } catch (e) {
        // Fallback to system temp directory
        cacheDir = Directory('${Directory.systemTemp.path}/netguard_cache');
        _cacheDirectory = cacheDir.path;
      }

      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }

      // Initialize Hive
      Hive.init(cacheDir.path);
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;

      // Clean expired entries on initialization
      await _clearExpired(options);

      logger('✅ NetGuard Cache initialized successfully.');
      return true;
    } catch (e) {
      _isInitialized = false;
      _initializationError = e.toString();
      logger('❌ NetGuard Cache Init Error: $e');
      return false;
    }
  }

  /// Auto-initialize if not already done (lazy loading)
  static Future<void> _initIfNeeded(NetGuardOptions options) async {
    if (!_isInitialized) {
      await initialize(options);
    }
  }

  /// Generate cache key from path and query parameters
  static String _generateKey(String path, Map<String, dynamic>? query) {
    final queryString = query != null ? jsonEncode(query) : '';
    return '${path}_$queryString';
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

      await _box.put(key, jsonEncode(entry));
      await _enforceMaxSize(options);
    } catch (e) {
      logger('❌ NetGuard Cache Save Error: $e');
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
      final cachedString = _box.get(key);
      if (cachedString == null) {
        logger('🔍 Cache miss for: $path');
        return null;
      }

      final cached = jsonDecode(cachedString);
      final expiry = options.cacheDuration ?? const Duration(minutes: 5);
      final timestamp = cached['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (age > expiry.inMilliseconds) {
        await _box.delete(key);
        logger('⏰ Cache expired for: $path');
        return null;
      }

      return cached['data'];
    } catch (e) {
      logger('❌ NetGuard Cache Get Error: $e');
      return null;
    }
  }

  /// Enforce maximum cache size
  static Future<void> _enforceMaxSize(NetGuardOptions options) async {
    try {
      final maxSize = options.maxCacheSize ?? 100;
      if (_box.length <= maxSize) return;

      final entries = <String, Map<String, dynamic>>{};
      for (var key in _box.keys) {
        final value = _box.get(key);
        if (value != null) {
          try {
            entries[key.toString()] = jsonDecode(value);
          } catch (e) {
            // Remove invalid entries
            await _box.delete(key);
          }
        }
      }

      final sortedKeys = entries.entries.toList()
        ..sort((a, b) => (a.value['timestamp'] as int).compareTo(b.value['timestamp'] as int));

      final toRemove = sortedKeys.take(entries.length - maxSize);
      for (var entry in toRemove) {
        await _box.delete(entry.key);
      }

      logger('🧹 Cache cleanup: removed old entries');
    } catch (e) {
      logger('❌ NetGuard Cache Size Enforcement Error: $e');
    }
  }

  /// Clear expired cache entries
  static Future<void> _clearExpired(NetGuardOptions options) async {
    try {
      final expiry = options.cacheDuration ?? const Duration(minutes: 5);
      final now = DateTime.now().millisecondsSinceEpoch;

      final keysToDelete = <dynamic>[];
      for (var key in _box.keys) {
        final cachedString = _box.get(key);
        if (cachedString != null) {
          try {
            final cached = jsonDecode(cachedString);
            if (cached is Map && cached['timestamp'] != null) {
              final age = now - cached['timestamp'];
              if (age > expiry.inMilliseconds) {
                keysToDelete.add(key);
              }
            }
          } catch (e) {
            // Remove invalid entries
            keysToDelete.add(key);
          }
        }
      }

      for (var key in keysToDelete) {
        await _box.delete(key);
      }

      if (keysToDelete.isNotEmpty) {
        logger('🗑️ Cleared expired cache entries');
      }
    } catch (e) {
      logger('❌ NetGuard Cache Clear Expired Error: $e');
    }
  }

  /// Clear all cache entries
  static Future<void> clearAll() async {
    try {
      if (_isInitialized) {
        final count = _box.length;
        await _box.clear();
        logger('🗑️ Cleared all $count cache entries');
      }
    } catch (e) {
      logger('❌ NetGuard Cache Clear All Error: $e');
    }
  }

  /// Check if cache is initialized
  static bool get isInitialized => _isInitialized;

  /// Get cache statistics
  static Map<String, dynamic> getStats() {
    if (!_isInitialized) {
      return {
        'platform': 'mobile/desktop',
        'isInitialized': false,
        'entryCount': 0,
        'storage': 'hive',
        'error': _initializationError,
        'directory': _cacheDirectory,
      };
    }

    return {
      'platform': 'mobile/desktop',
      'isInitialized': true,
      'entryCount': _box.length,
      'storage': 'hive',
      'directory': _cacheDirectory,
    };
  }

  /// Get detailed initialization information
  static Map<String, dynamic> getInitializationInfo() {
    return {
      'isInitialized': _isInitialized,
      'cacheDirectory': _cacheDirectory,
      'initializationError': _initializationError,
      'platform': 'mobile/desktop',
      'storage': 'hive',
      'boxName': _boxName,
    };
  }
}