import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
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
}

class UserRepository implements UserRepositoryInterface {
  final FirebaseAuthService _authService = FirebaseAuthService();

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
    return await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserModel?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    return await _authService.createUserWithEmailAndPassword(
      email: email,
      password: password,
      username: username,
      fullName: fullName,
    );
  }

  @override
  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  UserModel? getCurrentUser() {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) return null;

    return UserModel(
      uid: firebaseUser.uid,
      username: firebaseUser.displayName ?? 'user_${firebaseUser.uid.substring(0, 8)}',
      fullName: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email ?? '',
      bio: '',
      profileImageUrl: firebaseUser.photoURL ?? '',
      followers: [],
      following: [],
      posts: [],
      interests: [],
      isVerified: false,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _authService.authStateChanges.map((firebaseUser) {
      if (firebaseUser == null) return null;

      return UserModel(
        uid: firebaseUser.uid,
        username: firebaseUser.displayName ?? 'user_${firebaseUser.uid.substring(0, 8)}',
        fullName: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        bio: '',
        profileImageUrl: firebaseUser.photoURL ?? '',
        followers: [],
        following: [],
        posts: [],
        interests: [],
        isVerified: false,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      );
    });
  }
}