import '../../netguard.dart';
import '../utils/util.dart';

/// Simple implementation of AuthCallbacks for basic use cases with enhanced auto-refresh support
class AdvanceAuthCallbacks implements AuthCallbacks {
  String? _token;
  String? _refreshToken;

  final Future<String?> Function()? _onRefreshToken;
  final Future<void> Function(String newToken)? _onTokenRefreshed;
  final Future<void> Function()? _onLogout;

  AdvanceAuthCallbacks({
    String? initialToken,
    String? initialRefreshToken,
    Future<String?> Function()? onRefreshToken,
    Future<void> Function(String newToken)? onTokenRefreshed,
    Future<void> Function()? onLogout,
  }) : _token = initialToken,
        _refreshToken = initialRefreshToken,
        _onRefreshToken = onRefreshToken,
        _onTokenRefreshed = onTokenRefreshed,
        _onLogout = onLogout {

    // Debug logging
    logger('🔧 AdvanceAuthCallbacks initialized:');
    logger('   - Initial Token: ${(_token ?? '').isNotEmpty ?_token?.substring(0, 20) : ''}...');
    logger('   - Initial Refresh Token: ${(_refreshToken ?? '').isNotEmpty ?_refreshToken?.substring(0, 20) : ''}...');
    logger('   - onRefreshToken callback: ${_onRefreshToken != null ? 'SET' : 'NULL'}');
    logger('   - onTokenRefreshed callback: ${_onTokenRefreshed != null ? 'SET' : 'NULL'}');
    logger('   - onLogout callback: ${_onLogout != null ? 'SET' : 'NULL'}');
    logger('   - Auto-refresh ready: ${_onRefreshToken != null && (_token != null || _refreshToken != null)}');
  }

  @override
  Future<String?> getToken() async {
    logger('🔍 getToken() called, returning: ${_token?.substring(0, 20) ?? 'null'}...');
    return _token;
  }

  @override
  Future<String?> refreshToken() async {
    logger('🔄 refreshToken() called - AUTOMATIC REFRESH TRIGGERED');

    if (_onRefreshToken == null) {
      logger('❌ onRefreshToken callback is null! Auto-refresh cannot proceed.');
      return null;
    }

    // Check if we have a refresh token or some way to refresh
    if (_refreshToken == null && _token == null) {
      logger('❌ No refresh token or access token available for refresh');
      return null;
    }

    try {
      logger('📞 Calling user-provided onRefreshToken callback for automatic refresh...');
      logger('   - Current access token: ${_token?.substring(0, 20) ?? 'null'}...');
      logger('   - Current refresh token: ${_refreshToken?.substring(0, 20) ?? 'null'}...');

      final newToken = await _onRefreshToken();

      if (newToken != null && newToken.isNotEmpty) {
        logger('✅ Automatic refresh successful! New token: ${newToken.substring(0, 20)}...');
        _token = newToken; // Update internal token immediately
        return newToken;
      } else {
        logger('❌ Automatic refresh failed - callback returned null or empty token');
        return null;
      }
    } catch (e) {
      logger('❌ Exception during automatic token refresh: $e');
      return null;
    }
  }

  @override
  Future<void> onTokenRefreshed(String newToken) async {
    logger('💾 onTokenRefreshed() called with new token: ${newToken.substring(0, 20)}...');

    _token = newToken; // Always update internal token

    if (_onTokenRefreshed != null) {
      try {
        logger('📞 Calling user-provided onTokenRefreshed callback...');
        await _onTokenRefreshed(newToken);
        logger('✅ onTokenRefreshed callback completed successfully');
      } catch (e) {
        logger('❌ Exception in onTokenRefreshed callback: $e');
      }
    } else {
      logger('⚠️ onTokenRefreshed callback is null, only updating internal token');
    }
  }

  @override
  Future<void> onLogout() async {
    logger('👋 onLogout() called - clearing tokens and triggering logout');

    _token = null;
    _refreshToken = null;

    if (_onLogout != null) {
      try {
        logger('📞 Calling user-provided onLogout callback...');
        await _onLogout();
        logger('✅ onLogout callback completed successfully');
      } catch (e) {
        logger('❌ Exception in onLogout callback: $e');
      }
    } else {
      logger('⚠️ onLogout callback is null, only cleared internal tokens');
    }
  }

  /// Manually set tokens
  void setTokens({String? accessToken, String? refreshToken}) {
    logger('🔧 setTokens() called:');
    logger('   - Access Token: ${accessToken?.substring(0, 20) ?? 'null'}...');
    logger('   - Refresh Token: ${refreshToken?.substring(0, 20) ?? 'null'}...');

    if (accessToken != null) _token = accessToken;
    if (refreshToken != null) _refreshToken = refreshToken;

    logger('✅ Tokens updated - Auto-refresh ready: ${_onRefreshToken != null && (_token != null || _refreshToken != null)}');
  }

  /// Get current access token
  String? get currentToken => _token;

  /// Get refresh token
  String? get refreshTokenValue => _refreshToken;

  /// Check if has valid token
  bool get hasToken {
    final hasValidToken = _token != null && (_token ?? '').isNotEmpty;
    logger('🔍 hasToken check: $hasValidToken (token: ${_token?.substring(0, 20) ?? 'null'}...)');
    return hasValidToken;
  }

  /// Check if auto-refresh is properly configured
  bool get canAutoRefresh {
    final canRefresh = _onRefreshToken != null && (_refreshToken != null || _token != null);
    logger('🔍 canAutoRefresh check: $canRefresh');
    logger('   - Has refresh callback: ${_onRefreshToken != null}');
    logger('   - Has refresh token: ${_refreshToken != null}');
    logger('   - Has access token: ${_token != null}');
    return canRefresh;
  }

  /// Update just the access token (useful after refresh)
  void updateAccessToken(String newToken) {
    logger('🔄 updateAccessToken() called: ${newToken.substring(0, 20)}...');
    _token = newToken;
  }

  /// Clear all tokens
  void clearTokens() {
    logger('🗑️ clearTokens() called');
    _token = null;
    _refreshToken = null;
  }

  /// Get status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'hasAccessToken': _token != null,
      'hasRefreshToken': _refreshToken != null,
      'accessTokenLength': _token?.length ?? 0,
      'refreshTokenLength': _refreshToken?.length ?? 0,
      'hasRefreshCallback': _onRefreshToken != null,
      'hasTokenRefreshedCallback': _onTokenRefreshed != null,
      'hasLogoutCallback': _onLogout != null,
      'canAutoRefresh': canAutoRefresh,
    };
  }
}