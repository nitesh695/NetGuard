import '../../netguard.dart';

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
    print('🔧 AdvanceAuthCallbacks initialized:');
    print('   - Initial Token: ${_token?.substring(0, 20) ?? 'null'}...');
    print('   - Initial Refresh Token: ${_refreshToken?.substring(0, 20) ?? 'null'}...');
    print('   - onRefreshToken callback: ${_onRefreshToken != null ? 'SET' : 'NULL'}');
    print('   - onTokenRefreshed callback: ${_onTokenRefreshed != null ? 'SET' : 'NULL'}');
    print('   - onLogout callback: ${_onLogout != null ? 'SET' : 'NULL'}');
    print('   - Auto-refresh ready: ${_onRefreshToken != null && (_token != null || _refreshToken != null)}');
  }

  @override
  Future<String?> getToken() async {
    print('🔍 getToken() called, returning: ${_token?.substring(0, 20) ?? 'null'}...');
    return _token;
  }

  @override
  Future<String?> refreshToken() async {
    print('🔄 refreshToken() called - AUTOMATIC REFRESH TRIGGERED');

    if (_onRefreshToken == null) {
      print('❌ onRefreshToken callback is null! Auto-refresh cannot proceed.');
      return null;
    }

    // Check if we have a refresh token or some way to refresh
    if (_refreshToken == null && _token == null) {
      print('❌ No refresh token or access token available for refresh');
      return null;
    }

    try {
      print('📞 Calling user-provided onRefreshToken callback for automatic refresh...');
      print('   - Current access token: ${_token?.substring(0, 20) ?? 'null'}...');
      print('   - Current refresh token: ${_refreshToken?.substring(0, 20) ?? 'null'}...');

      final newToken = await _onRefreshToken!();

      if (newToken != null && newToken.isNotEmpty) {
        print('✅ Automatic refresh successful! New token: ${newToken.substring(0, 20)}...');
        _token = newToken; // Update internal token immediately
        return newToken;
      } else {
        print('❌ Automatic refresh failed - callback returned null or empty token');
        return null;
      }
    } catch (e) {
      print('❌ Exception during automatic token refresh: $e');
      return null;
    }
  }

  @override
  Future<void> onTokenRefreshed(String newToken) async {
    print('💾 onTokenRefreshed() called with new token: ${newToken.substring(0, 20)}...');

    _token = newToken; // Always update internal token

    if (_onTokenRefreshed != null) {
      try {
        print('📞 Calling user-provided onTokenRefreshed callback...');
        await _onTokenRefreshed!(newToken);
        print('✅ onTokenRefreshed callback completed successfully');
      } catch (e) {
        print('❌ Exception in onTokenRefreshed callback: $e');
      }
    } else {
      print('⚠️ onTokenRefreshed callback is null, only updating internal token');
    }
  }

  @override
  Future<void> onLogout() async {
    print('👋 onLogout() called - clearing tokens and triggering logout');

    _token = null;
    _refreshToken = null;

    if (_onLogout != null) {
      try {
        print('📞 Calling user-provided onLogout callback...');
        await _onLogout!();
        print('✅ onLogout callback completed successfully');
      } catch (e) {
        print('❌ Exception in onLogout callback: $e');
      }
    } else {
      print('⚠️ onLogout callback is null, only cleared internal tokens');
    }
  }

  /// Manually set tokens
  void setTokens({String? accessToken, String? refreshToken}) {
    print('🔧 setTokens() called:');
    print('   - Access Token: ${accessToken?.substring(0, 20) ?? 'null'}...');
    print('   - Refresh Token: ${refreshToken?.substring(0, 20) ?? 'null'}...');

    if (accessToken != null) _token = accessToken;
    if (refreshToken != null) _refreshToken = refreshToken;

    print('✅ Tokens updated - Auto-refresh ready: ${_onRefreshToken != null && (_token != null || _refreshToken != null)}');
  }

  /// Get current access token
  String? get currentToken => _token;

  /// Get refresh token
  String? get refreshTokenValue => _refreshToken;

  /// Check if has valid token
  bool get hasToken {
    final hasValidToken = _token != null && _token!.isNotEmpty;
    print('🔍 hasToken check: $hasValidToken (token: ${_token?.substring(0, 20) ?? 'null'}...)');
    return hasValidToken;
  }

  /// Check if auto-refresh is properly configured
  bool get canAutoRefresh {
    final canRefresh = _onRefreshToken != null && (_refreshToken != null || _token != null);
    print('🔍 canAutoRefresh check: $canRefresh');
    print('   - Has refresh callback: ${_onRefreshToken != null}');
    print('   - Has refresh token: ${_refreshToken != null}');
    print('   - Has access token: ${_token != null}');
    return canRefresh;
  }

  /// Update just the access token (useful after refresh)
  void updateAccessToken(String newToken) {
    print('🔄 updateAccessToken() called: ${newToken.substring(0, 20)}...');
    _token = newToken;
  }

  /// Clear all tokens
  void clearTokens() {
    print('🗑️ clearTokens() called');
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