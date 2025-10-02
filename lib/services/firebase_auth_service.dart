import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return _userFromFirebaseUser(result.user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserModel?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    try {
      final UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(fullName);

        return UserModel(
          uid: result.user!.uid,
          username: username,
          fullName: fullName,
          email: email,
          bio: '',
          profileImageUrl: '',
          followers: [],
          following: [],
          posts: [],
          interests: [],
          isVerified: false,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  UserModel? _userFromFirebaseUser(User? user) {
    if (user == null) return null;

    return UserModel(
      uid: user.uid,
      username: user.displayName ?? 'user_${user.uid.substring(0, 8)}',
      fullName: user.displayName ?? 'User',
      email: user.email ?? '',
      bio: '',
      profileImageUrl: user.photoURL ?? '',
      followers: [],
      following: [],
      posts: [],
      interests: [],
      isVerified: false,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}