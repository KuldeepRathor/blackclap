import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_url.dart';
import 'token_storage.dart';
import 'http_logger.dart';

class ApiService {
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

  Future<http.Response> _sendRequest(
    String method,
    Uri url, {
    bool requireAuth = true,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final defaultHeaders = await _getHeaders(requireAuth: requireAuth);
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    HttpLogger.logRequest(method, url, headers: defaultHeaders, body: body);

    final startTime = DateTime.now();
    try {
      http.Response response;
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: defaultHeaders);
          break;
        case 'POST':
          response = await http.post(url, headers: defaultHeaders, body: body);
          break;
        case 'PATCH':
          response = await http.patch(url, headers: defaultHeaders, body: body);
          break;
        case 'PUT':
          response = await http.put(url, headers: defaultHeaders, body: body);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: defaultHeaders);
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

  // --- Media Image Upload Flow (2-Step Direct Upload) ---

  Future<String> uploadProfileImage(File file) async {
    final fileName = file.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();
    
    // Determine MIME type
    String fileType = 'image/jpeg';
    if (fileExtension == 'png') {
      fileType = 'image/png';
    } else if (fileExtension == 'gif') {
      fileType = 'image/gif';
    }

    // Step 1: Request presigned upload URL
    final presignedUrl = Uri.parse(AppUrl.presignedUrl);
    final presignedResponse = await _sendRequest(
      'POST',
      presignedUrl,
      requireAuth: true,
      body: json.encode({
        'file_name': fileName,
        'file_type': fileType,
        'purpose': 'avatar',
      }),
    );

    if (presignedResponse.statusCode != 200) {
      throw Exception('Failed to get upload authorization: ${_parseError(presignedResponse)}');
    }

    final presignedData = json.decode(presignedResponse.body) as Map<String, dynamic>;
    final uploadUrl = presignedData['upload_url'] as String;
    final downloadUrl = presignedData['download_url'] as String;

    // Step 2: Upload file binary directly
    final fileBytes = await file.readAsBytes();
    final uploadResponse = await _sendRequest(
      'PUT',
      Uri.parse(uploadUrl),
      requireAuth: false,
      headers: {
        'Content-Type': fileType,
      },
      body: fileBytes,
    );

    if (uploadResponse.statusCode != 200 && uploadResponse.statusCode != 201) {
      throw Exception('Failed to upload image data.');
    }

    // Step 3: Link the uploaded image to the user's profile
    await updateMe({
      'avatar_url': downloadUrl,
    });

    return downloadUrl;
  }
}
