import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String username;
  final String fullName;
  final String email;
  final String bio;
  final String profileImageUrl;
  final List<String> followers;
  final List<String> following;
  final List<String> posts;
  final List<String> interests;
  final bool isVerified;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.username,
    required this.fullName,
    required this.email,
    required this.bio,
    required this.profileImageUrl,
    required this.followers,
    required this.following,
    required this.posts,
    required this.interests,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      posts: List<String>.from(map['posts'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'fullName': fullName,
      'email': email,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'followers': followers,
      'following': following,
      'posts': posts,
      'interests': interests,
      'isVerified': isVerified,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? fullName,
    String? email,
    String? bio,
    String? profileImageUrl,
    List<String>? followers,
    List<String>? following,
    List<String>? posts,
    List<String>? interests,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      posts: posts ?? this.posts,
      interests: interests ?? this.interests,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        username,
        fullName,
        email,
        bio,
        profileImageUrl,
        followers,
        following,
        posts,
        interests,
        isVerified,
        createdAt,
      ];
}