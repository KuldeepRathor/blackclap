class AppUrl {
  // ─── Domain Configuration ────────────────────────────────────────────────

  // 10.0.2.2 → Android emulator, 192.168.x.x → physical device (must be same Wi-Fi)
  static const String _devHost = '192.168.31.139'; //(physical device)
  // static const String _devHost = '10.0.2.2';//(android emulator)
  static const String _devPort = '8000';

  // Update _prodHost when deploying to production
  static const String _prodHost = 'api.blackclap.com';

  static const bool _isProduction = true; // toggle for prod builds

  static String get _host {
    if (_isProduction) return 'https://$_prodHost';
    return 'http://$_devHost:$_devPort';
  }

  static String get _wsHost {
    if (_isProduction) return 'wss://$_prodHost';
    return 'ws://$_devHost:$_devPort';
  }

  static String get baseUrl => '$_host/api/v1';

  /// WebSocket base, derived from the same host so dev/prod stay in sync.
  static String get wsBaseUrl => '$_wsHost/api/v1';

  // ─── Auth ────────────────────────────────────────────────────────────────

  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get verifyResetCode => '$baseUrl/auth/verify-reset-code';
  static String get resetPassword => '$baseUrl/auth/reset-password';
  static String get refresh => '$baseUrl/auth/refresh';
  static String get logout => '$baseUrl/auth/logout';
  static String get logoutAll => '$baseUrl/auth/logout-all';

  // ─── Users & Profiles ────────────────────────────────────────────────────

  static String get me => '$baseUrl/users/me';
  static String userProfile(String username) => '$baseUrl/users/$username';

  // ─── Posts ───────────────────────────────────────────────────────────────

  static String get myPosts => '$baseUrl/posts/me';
  static String userPosts(String username) => '$baseUrl/posts/user/$username';

  // ─── Follows ─────────────────────────────────────────────────────────────

  static String followUser(String username) => '$baseUrl/follows/$username';
  static String unfollowUser(String username) => '$baseUrl/follows/$username';
  static String followers(String username) =>
      '$baseUrl/follows/$username/followers';
  static String following(String username) =>
      '$baseUrl/follows/$username/following';

  // ─── Uploads ─────────────────────────────────────────────────────────────

  // ─── Search ───────────────────────────────────────────────────────────────

  static String get search => '$baseUrl/search';

  // ─── Uploads ─────────────────────────────────────────────────────────────

  /// Request a short-lived SAS upload URL from Azure Blob Storage.
  /// POST body: { "filename": "photo.jpg", "upload_type": "profile_image" }
  /// Response: { "upload_url", "blob_url", "blob_name", "content_type", "expires_in_seconds" }
  static String get uploadUrl => '$baseUrl/uploads/url';

  // ─── Devices / Push ──────────────────────────────────────────────────────

  /// Relative paths for ApiService generic post()/delete() (which prepend
  /// baseUrl). Register the current device's FCM token, or unregister it.
  static String get registerDevice => '/devices';
  static String unregisterDevice(String token) => '/devices/$token';

  // ─── Chat ────────────────────────────────────────────────────────────────

  /// REST chat paths are passed as relative strings to ApiService (which
  /// prepends baseUrl); only the WebSocket needs a full URL here.
  /// JWT is passed as a query param because WS clients can't set headers.
  static String get chatSocket => '$wsBaseUrl/ws/chat';
}
