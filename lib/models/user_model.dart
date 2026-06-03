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
  final int? postsCount;
  final int? followersCount;
  final int? followingCount;

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
    this.postsCount,
    this.followersCount,
    this.followingCount,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      if (map['createdAt'] is DateTime) {
        parsedDate = map['createdAt'];
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.parse(map['createdAt']);
      } else if (map['created_at'] is String) {
        parsedDate = DateTime.parse(map['created_at']);
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return UserModel(
      uid: map['id']?.toString() ?? map['uid']?.toString() ?? '',
      username: map['username'] ?? '',
      fullName: map['display_name'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      profileImageUrl: map['avatar_url'] ?? map['profileImageUrl'] ?? '',
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      posts: List<String>.from(map['posts'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      isVerified: map['is_active'] ?? map['isVerified'] ?? false,
      createdAt: parsedDate,
      postsCount: map['posts_count'] ?? map['postsCount'],
      followersCount: map['followers_count'] ?? map['followersCount'],
      followingCount: map['following_count'] ?? map['followingCount'],
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
      'createdAt': createdAt.toIso8601String(),
      'postsCount': postsCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
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
    int? postsCount,
    int? followersCount,
    int? followingCount,
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
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
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
        postsCount,
        followersCount,
        followingCount,
      ];
}