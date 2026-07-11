import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_url.dart';
import 'token_storage.dart';
import 'http_logger.dart';

class ApiService {
  /// Invoked when a refresh attempt confirms the session is truly dead (the
  /// refresh token itself was rejected — expired, revoked, or reused). Wired
  /// up once at app startup by UserRepository to trigger a real logout.
  static void Function()? onSessionExpired;

  /// Shared across every ApiService instance (there's no DI container here —
  /// ApiService is instantiated fresh in many places) so concurrent 401s
  /// piggyback on the same refresh attempt instead of racing the rotating
  /// refresh token against each other.
  static Future<bool>? _refreshInFlight;

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await TokenStorage.getAccessToken();
      if (token != null) { 
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  String _parseError(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded.containsKey('detail')) {
        final detail = decoded['detail'];
        if (detail is String) {
          return detail;
        } else if (detail is List && detail.isNotEmpty) {
          final firstError = detail.first;
          if (firstError is Map && firstError.containsKey('msg')) {
            return firstError['msg'].toString();
          }
        }
      }
    } catch (_) {}
    return 'Server error (status ${response.statusCode})';
  }

  Future<http.Response> _performOnce(
    String method,
    Uri url, {
    required bool requireAuth,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final defaultHeaders = await _getHeaders(requireAuth: requireAuth);
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    HttpLogger.logRequest(method, url, headers: defaultHeaders, body: body);

    const timeout = Duration(seconds: 10);
    final startTime = DateTime.now();
    try {
      http.Response response;
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: defaultHeaders).timeout(timeout);
          break;
        case 'POST':
          response = await http.post(url, headers: defaultHeaders, body: body).timeout(timeout);
          break;
        case 'PATCH':
          response = await http.patch(url, headers: defaultHeaders, body: body).timeout(timeout);
          break;
        case 'PUT':
          response = await http.put(url, headers: defaultHeaders, body: body).timeout(timeout);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: defaultHeaders).timeout(timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      final duration = DateTime.now().difference(startTime);

      HttpLogger.logResponse(
        response.statusCode,
        method,
        url,
        headers: response.headers,
        body: response.body,
        duration: duration,
      );

      return response;
    } catch (e) {
      HttpLogger.logError(method, url, e);
      rethrow;
    }
  }

  /// Sends a request; on a 401 from an auth-required call, silently attempts
  /// one token refresh and retries the request exactly once. Set
  /// [allowAuthRetry] to false for the auth endpoints themselves (login,
  /// register, refresh, logout) where a 401 is a real failure, not an
  /// expired-token situation.
  Future<http.Response> _sendRequest(
    String method,
    Uri url, {
    bool requireAuth = true,
    dynamic body,
    Map<String, String>? headers,
    bool allowAuthRetry = true,
  }) async {
    final response = await _performOnce(
      method,
      url,
      requireAuth: requireAuth,
      body: body,
      headers: headers,
    );

    if (response.statusCode == 401 && requireAuth && allowAuthRetry) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _performOnce(
          method,
          url,
          requireAuth: requireAuth,
          body: body,
          headers: headers,
        );
      }
    }
    return response;
  }

  /// Deduplicates concurrent refresh attempts: if a refresh is already in
  /// flight (started by another request that also 401'd), piggyback on it
  /// instead of racing it with a second /auth/refresh call — the refresh
  /// token rotates, so only one attempt can ever succeed.
  Future<bool> _refreshAccessToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http
          .post(
            Uri.parse(AppUrl.refresh),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        await TokenStorage.saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
        return true;
      }

      // Refresh token itself was rejected — the session is truly dead.
      ApiService.onSessionExpired?.call();
      return false;
    } catch (_) {
      // Network/timeout talking to /auth/refresh — a transient failure, not
      // a confirmed-dead session. Don't force a logout on a flaky network.
      return false;
    }
  }

  // --- Auth API ---

  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final url = Uri.parse(AppUrl.register);
    final response = await _sendRequest(
      'POST',
      url,
      requireAuth: false,
      allowAuthRetry: false,
      body: json.encode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return data['user'] as Map<String, dynamic>;
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<Map<String, dynamic>> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final url = Uri.parse(AppUrl.login);
    final response = await _sendRequest(
      'POST',
      url,
      requireAuth: false,
      allowAuthRetry: false,
      body: json.encode({
        'email_or_username': emailOrUsername,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return data['user'] as Map<String, dynamic>;
    } else {
      throw Exception(_parseError(response));
    }
  }

  /// Request a password-reset code be emailed. The backend always responds 200
  /// with a generic message (it never reveals whether the email is registered).
  Future<void> requestPasswordReset(String email) async {
    final response = await _sendRequest(
      'POST',
      Uri.parse(AppUrl.forgotPassword),
      requireAuth: false,
      body: json.encode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  /// Validate a reset code without consuming it (gates the new-password screen).
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final response = await _sendRequest(
      'POST',
      Uri.parse(AppUrl.verifyResetCode),
      requireAuth: false,
      body: json.encode({'email': email, 'code': code}),
    );
    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  /// Consume the reset code and set a new password.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _sendRequest(
      'POST',
      Uri.parse(AppUrl.resetPassword),
      requireAuth: false,
      body: json.encode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  /// Revokes a single refresh token server-side. The backend always returns
  /// 200 (logout is idempotent), so this never throws on a 401.
  Future<void> logout(String refreshToken) async {
    await _sendRequest(
      'POST',
      Uri.parse(AppUrl.logout),
      requireAuth: false,
      allowAuthRetry: false,
      body: json.encode({'refresh_token': refreshToken}),
    );
  }

  /// Revokes every refresh token for the current user (all devices).
  Future<void> logoutAll() async {
    final response = await _sendRequest('POST', Uri.parse(AppUrl.logoutAll), body: '{}');
    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  // --- Users & Profiles API ---

  Future<Map<String, dynamic>> getMe() async {
    final url = Uri.parse(AppUrl.me);
    final response = await _sendRequest(
      'GET',
      url,
      requireAuth: true,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> fields) async {
    final url = Uri.parse(AppUrl.me);
    final response = await _sendRequest(
      'PATCH',
      url,
      requireAuth: true,
      body: json.encode(fields),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_parseError(response));
    }
  }

  /// Soft-deletes the authenticated user's account (30-day grace period; the
  /// account is restored by logging back in before then). Backend: DELETE /users/me.
  Future<void> deleteMe() async {
    final url = Uri.parse(AppUrl.me);
    final response = await _sendRequest('DELETE', url, requireAuth: true);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_parseError(response));
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String username) async {
    final url = Uri.parse(AppUrl.userProfile(username));
    final response = await _sendRequest(
      'GET',
      url,
      requireAuth: true,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<Map<String, dynamic>> followUser(String username) async {
    final url = Uri.parse(AppUrl.followUser(username));
    final response = await _sendRequest('POST', url, requireAuth: true);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<Map<String, dynamic>> unfollowUser(String username) async {
    final url = Uri.parse(AppUrl.unfollowUser(username));
    final response = await _sendRequest('DELETE', url, requireAuth: true);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_parseError(response));
    }
  }

  // --- Generic helpers for service classes ---

  Future<List<dynamic>> getList(String path) async {
    final url = Uri.parse('${AppUrl.baseUrl}$path');
    final response = await _sendRequest('GET', url, requireAuth: true);

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppUrl.baseUrl}$path');
    final response = await _sendRequest(
      'POST',
      url,
      requireAuth: true,
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse('${AppUrl.baseUrl}$path');
    final response = await _sendRequest('GET', url, requireAuth: true);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<void> postVoid(String path) async {
    final url = Uri.parse('${AppUrl.baseUrl}$path');
    final response = await _sendRequest('POST', url, requireAuth: true, body: '{}');
    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
      throw Exception(_parseError(response));
    }
  }

  Future<void> delete(String path) async {
    final url = Uri.parse('${AppUrl.baseUrl}$path');
    final response = await _sendRequest('DELETE', url, requireAuth: true);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_parseError(response));
    }
  }

  Future<void> putBytes(
    String url,
    Uint8List bytes,
    String contentType,
  ) async {
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': contentType,
        'x-ms-blob-type': 'BlockBlob',
      },
      body: bytes,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to upload bytes to storage (${response.statusCode}).',
      );
    }
  }

  // --- Upload Flow (2-Step Azure SAS Direct Upload) ---

  /// Uploads a profile image and returns the public blob URL.
  ///
  /// Step 1 — POST /uploads/url  →  get a short-lived Azure SAS upload URL.
  // ignore: unintended_html_in_doc_comment
  /// Step 2 — PUT <sas_url>      →  stream the file directly to Azure Blob Storage.
  /// Step 3 — PATCH /users/me    →  persist the blob URL on the user profile.
  Future<String> uploadProfileImage(File file) async {
    final fileName = file.path.split('/').last.toLowerCase();

    // Step 1: Request SAS upload URL from the backend
    final sasRequestResponse = await _sendRequest(
      'POST',
      Uri.parse(AppUrl.uploadUrl),
      requireAuth: true,
      body: json.encode({
        'filename': fileName,
        'upload_type': 'profile_image',
      }),
    );

    if (sasRequestResponse.statusCode != 200) {
      throw Exception(
        'Failed to get upload URL: ${_parseError(sasRequestResponse)}',
      );
    }

    final sasData =
        json.decode(sasRequestResponse.body) as Map<String, dynamic>;
    final uploadUrl = sasData['upload_url'] as String;
    final blobUrl = sasData['blob_url'] as String;
    final contentType = sasData['content_type'] as String;

    // Step 2: PUT file binary directly to Azure Blob Storage via SAS URL.
    // x-ms-blob-type is required by Azure for block blob uploads.
    final fileBytes = await file.readAsBytes();
    final azureUploadResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
        'x-ms-blob-type': 'BlockBlob',
      },
      body: fileBytes,
    );

    if (azureUploadResponse.statusCode != 200 &&
        azureUploadResponse.statusCode != 201) {
      throw Exception(
        'Failed to upload file to storage (${azureUploadResponse.statusCode}).',
      );
    }

    // Step 3: Persist the blob URL on the user profile
    await updateMe({'avatar_url': blobUrl});

    return blobUrl;
  }
}
