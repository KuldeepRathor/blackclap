import 'dart:io';
import 'package:flutter/foundation.dart';

class AppUrl {
  // ─── Domain Configuration ────────────────────────────────────────────────

  static const String _devHost = 'localhost';
  static const String _devPort = '8000';

  // Update _prodHost when deploying to production
  static const String _prodHost = 'api.blackclap.com';

  static const bool _isProduction = true; // toggle for prod builds

  static String get _host {
    if (_isProduction) return 'https://$_prodHost';
    // Android emulator routes to host machine via 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:$_devPort';
    return 'http://$_devHost:$_devPort';
  }

  static String get baseUrl => '$_host/api/v1';

  // ─── Auth ────────────────────────────────────────────────────────────────

  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';

  // ─── Users & Profiles ────────────────────────────────────────────────────

  static String get me => '$baseUrl/users/me';
  static String userProfile(String username) => '$baseUrl/users/$username';

  // ─── Uploads ─────────────────────────────────────────────────────────────

  /// Request a short-lived SAS upload URL from Azure Blob Storage.
  /// POST body: { "filename": "photo.jpg", "upload_type": "profile_image" }
  /// Response: { "upload_url", "blob_url", "blob_name", "content_type", "expires_in_seconds" }
  static String get uploadUrl => '$baseUrl/uploads/url';
}
