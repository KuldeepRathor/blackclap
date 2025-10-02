import 'package:equatable/equatable.dart';

class StoryModel extends Equatable {
  final String id;
  final String uid;
  final String username;
  final String profileImageUrl;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;

  const StoryModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.profileImageUrl,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
  });

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    return StoryModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'createdAt': createdAt,
    };
  }

  StoryModel copyWith({
    String? id,
    String? uid,
    String? username,
    String? profileImageUrl,
    String? imageUrl,
    String? caption,
    DateTime? createdAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        uid,
        username,
        profileImageUrl,
        imageUrl,
        caption,
        createdAt,
      ];
}