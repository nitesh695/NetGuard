import 'dart:convert';
import 'package:netguard/src/netguard_options.dart';

// Platform detection
import 'dart:io' if (dart.library.html) 'dart:html' as platform;

// Conditional imports for different platforms
import 'cache_managers/mobile_cache_manager.dart' if (dart.library.html) 'cache_managers/web_cache_manager.dart' as cache_impl;

/// Universal cache manager that works across all platforms
abstract class CacheManager {
  /// Manually initialize the cache manager (optional)
  /// This is useful if you want to initialize upfront instead of lazy loading
  // static Future<bool> initialize(NetGuardOptions options) async {
  //   return cache_impl.CacheManagerImpl.initialize(options);
  // }

  /// Save response to cache
  static Future<void> saveResponse({
    required NetGuardOptions options,
    required String path,
    Map<String, dynamic>? query,
    required dynamic response,
  }) async {
    return cache_impl.CacheManagerImpl.saveResponse(
      options: options,
      path: path,
      query: query,
      response: response,
    );
  }

  /// Get response from cache
  static Future<dynamic> getResponse({
    required NetGuardOptions options,
    required String path,
    Map<String, dynamic>? query,
  }) async {
    return cache_impl.CacheManagerImpl.getResponse(
      options: options,
      path: path,
      query: query,
    );
  }

  /// Clear all cache entries
  static Future<void> clearAll() async {
    return cache_impl.CacheManagerImpl.clearAll();
  }

  /// Check if cache is initialized and working
  static bool get isInitialized => cache_impl.CacheManagerImpl.isInitialized;

  /// Get cache statistics
  static Map<String, dynamic> getStats() {
    return cache_impl.CacheManagerImpl.getStats();
  }

  /// Get detailed initialization info for debugging
  static Map<String, dynamic> getInitializationInfo() {
    return cache_impl.CacheManagerImpl.getInitializationInfo();
  }
}