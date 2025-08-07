import '../../netguard.dart';

/// Simple implementation of AuthCallbacks for basic use cases
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
        _onLogout = onLogout;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<String?> refreshToken() async {
    if (_onRefreshToken != null) {
      final newToken = await _onRefreshToken!();
      if (newToken != null) {
        _token = newToken;
      }
      return newToken;
    }
    return null;
  }

  @override
  Future<void> onTokenRefreshed(String newToken) async {
    _token = newToken;
    if (_onTokenRefreshed != null) {
      await _onTokenRefreshed!(newToken);
    }
  }

  @override
  Future<void> onLogout() async {
    _token = null;
    _refreshToken = null;
    if (_onLogout != null) {
      await _onLogout!();
    }
  }

  /// Manually set tokens
  void setTokens({String? accessToken, String? refreshToken}) {
    _token = accessToken;
    _refreshToken = refreshToken;
  }

  /// Get refresh token
  String? get refreshTokenValue => _refreshToken;

  /// Check if has valid token
  bool get hasToken => _token != null && _token!.isNotEmpty;
}