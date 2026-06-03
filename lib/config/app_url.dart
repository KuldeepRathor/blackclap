import 'dart:io';
import 'package:flutter/foundation.dart';

class AppUrl {
  // Use 10.0.2.2 for Android emulator, localhost for iOS/Web/Desktop
  static final String baseUrl = (!kIsWeb && Platform.isAndroid)
      ? 'http://10.0.2.2:8000/api/v1'
      : 'http://localhost:8000/api/v1';

  // Auth endpoints
  static final String register = '$baseUrl/auth/register';
  static final String login = '$baseUrl/auth/login';

  // User & Profile endpoints
  static final String me = '$baseUrl/users/me';
  static String userProfile(String username) => '$baseUrl/users/$username';

  // Media endpoints
  static final String presignedUrl = '$baseUrl/media/presigned-url';
}
