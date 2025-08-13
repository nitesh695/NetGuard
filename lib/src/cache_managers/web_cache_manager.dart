import 'dart:convert';
import 'package:hive/hive.dart';
import '../../netguard.dart';
import '../utils/util.dart';

class CacheManagerImpl {
  static const String _boxName = 'netguard_web_cache';
  static const String _keyPrefix = 'netguard_cache_';
  static bool _isInitialized = false;
  static String? _initializationError;

  /// Initialize Hive cache for web
  static Future<bool> initialize(NetGuardOptions options) async {
    try {
      _initializationError = null;

      if (!_isInitialized) {
        await Hive.openBox<String>(_boxName);
      }

      _isInitialized = true;
      logger('✅ NetGuard Web Cache (Hive) initialized successfully');
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
      final entry = jsonEncode({
        'data': response,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final box = Hive.box<String>(_boxName);
      await box.put(key, entry);
      await _enforceMaxSize(options);
    } catch (e) {
      logger('❌ NetGuard Web Cache Save Error: $e');
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
      final box = Hive.box<String>(_boxName);
      final cachedString = box.get(key);
      if (cachedString == null) {
        logger('🔍 Web cache miss for: $path');
        return null;
      }

      final cached = jsonDecode(cachedString);
      final expiry = options.cacheDuration ?? const Duration(minutes: 5);
      final timestamp = cached['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (age > expiry.inMilliseconds) {
        await box.delete(key);
        logger('⏰ Web cache expired for: $path');
        return null;
      }

      logger('🎯 Web cache hit for: $path');
      return cached['data'];
    } catch (e) {
      logger('❌ NetGuard Web Cache Get Error: $e');
      return null;
    }
  }

  /// Enforce maximum cache size
  static Future<void> _enforceMaxSize(NetGuardOptions options) async {
    try {
      final maxSize = options.maxCacheSize ?? 100;
      final box = Hive.box<String>(_boxName);
      final cacheKeys = box.keys.where((key) => key.toString().startsWith(_keyPrefix)).toList();

      if (cacheKeys.length <= maxSize) return;

      final entries = <String, Map<String, dynamic>>{};
      for (var key in cacheKeys) {
        final value = box.get(key);
        if (value != null) {
          try {
            entries[key.toString()] = jsonDecode(value);
          } catch (_) {
            await box.delete(key);
          }
        }
      }

      final sortedKeys = entries.entries.toList()
        ..sort((a, b) => (a.value['timestamp'] as int).compareTo(b.value['timestamp'] as int));

      final toRemove = sortedKeys.take(entries.length - maxSize);
      for (var entry in toRemove) {
        await box.delete(entry.key);
      }

      logger('🧹 Web cache cleanup: removed ${toRemove.length} old entries');
    } catch (e) {
      logger('❌ NetGuard Web Cache Size Enforcement Error: $e');
    }
  }

  /// Clear all cache entries
  static Future<void> clearAll() async {
    try {
      final box = Hive.box<String>(_boxName);
      final keysToRemove = box.keys.where((key) => key.toString().startsWith(_keyPrefix)).toList();

      for (var key in keysToRemove) {
        await box.delete(key);
      }

      logger('🗑️ Web cache cleared ${keysToRemove.length} entries');
    } catch (e) {
      logger('❌ NetGuard Web Cache Clear All Error: $e');
    }
  }

  /// Check if cache is initialized
  static bool get isInitialized => _isInitialized;

  /// Get cache statistics
  static Map<String, dynamic> getStats() {
    final box = Hive.box<String>(_boxName);
    final cacheKeys = box.keys.where((key) => key.toString().startsWith(_keyPrefix)).toList();

    return {
      'platform': 'web',
      'isInitialized': _isInitialized,
      'entryCount': cacheKeys.length,
      'storage': 'hive',
      'error': _initializationError,
    };
  }

  /// Get detailed initialization information
  static Map<String, dynamic> getInitializationInfo() {
    return {
      'isInitialized': _isInitialized,
      'initializationError': _initializationError,
      'platform': 'web',
      'storage': 'hive',
    };
  }
}
