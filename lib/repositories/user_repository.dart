import 'dart:async';
import 'dart:io';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';
import 'mock_data_service.dart';

abstract class UserRepositoryInterface {
  Future<List<UserModel>> getUsers();
  Future<UserModel?> getUser(String uid);
  Future<List<UserModel>> searchUsers(String query);
  Future<void> followUser(String currentUserId, String targetUserId);
  Future<void> unfollowUser(String currentUserId, String targetUserId);
  Future<UserModel?> signInWithEmailAndPassword(String email, String password);
  Future<UserModel?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String fullName,
  });
  Future<void> signOut();
  UserModel? getCurrentUser();
  Stream<UserModel?> get authStateChanges;
  
  // Custom API additions
  Future<UserModel?> getProfile();
  Future<UserModel?> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? email,
    String? avatarUrl,
  });
  Future<String> uploadAvatar(String filePath);
}

class UserRepository implements UserRepositoryInterface {
  final ApiService _apiService = ApiService();
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();
  UserModel? _cachedUser;

  @override
  Future<List<UserModel>> getUsers() async {
    final userData = MockDataService.getUsers();
    return userData.map((user) => UserModel.fromMap(user)).toList();
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    final userData = MockDataService.getUser(uid);
    return userData != null ? UserModel.fromMap(userData) : null;
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    final userData = MockDataService.searchUsers(query);
    return userData.map((user) => UserModel.fromMap(user)).toList();
  }

  @override
  Future<void> followUser(String currentUserId, String targetUserId) async {
    await MockDataService.followUser(currentUserId, targetUserId);
  }

  @override
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await MockDataService.unfollowUser(currentUserId, targetUserId);
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userMap = await _apiService.login(
        emailOrUsername: email,
        password: password,
      );
      final user = UserModel.fromMap(userMap);
      _cachedUser = user;
      _authStateController.add(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    try {
      final userMap = await _apiService.register(
        email: email,
        username: username,
        password: password,
      );

      var user = UserModel.fromMap(userMap);

      if (fullName.isNotEmpty && fullName != username) {
        final updatedUserMap = await _apiService.updateMe({
          'display_name': fullName,
        });
        user = UserModel.fromMap(updatedUserMap);
      }

      _cachedUser = user;
      _authStateController.add(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await TokenStorage.clearTokens();
    _cachedUser = null;
    _authStateController.add(null);
  }

  @override
  UserModel? getCurrentUser() {
    return _cachedUser;
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  // Custom API endpoints

  @override
  Future<UserModel?> getProfile() async {
    try {
      final userMap = await _apiService.getMe();
      final user = UserModel.fromMap(userMap);
      _cachedUser = user;
      _authStateController.add(user);
      return user;
    } catch (e) {
      // On any error (network, server, etc.), return the cached user so we don't
      // accidentally sign the user out during a background profile refresh.
      // The only intentional logout paths are: explicit AuthLogoutRequested,
      // or AuthCheckRequested finding no valid token at startup.
      return _cachedUser;
    }
  }

  @override
  Future<UserModel?> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      final fields = <String, dynamic>{};
      if (displayName != null) fields['display_name'] = displayName;
      if (username != null) fields['username'] = username;
      if (bio != null) fields['bio'] = bio;
      if (email != null) fields['email'] = email;
      if (avatarUrl != null) fields['avatar_url'] = avatarUrl;

      if (fields.isEmpty) return _cachedUser;

      final updatedUserMap = await _apiService.updateMe(fields);
      final user = UserModel.fromMap(updatedUserMap);
      _cachedUser = user;
      _authStateController.add(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    try {
      final file = File(filePath);
      final downloadUrl = await _apiService.uploadProfileImage(file);
      
      // Update cached user avatar url locally as well
      if (_cachedUser != null) {
        _cachedUser = _cachedUser!.copyWith(profileImageUrl: downloadUrl);
        _authStateController.add(_cachedUser);
      }
      
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }
}