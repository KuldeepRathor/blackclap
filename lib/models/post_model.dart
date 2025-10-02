import 'package:equatable/equatable.dart';

enum MediaType { image, video, text }

class PostModel extends Equatable {
  final String id;
  final String uid;
  final String username;
  final String fullName;
  final String profileImageUrl;
  final String caption;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final MediaType mediaType;
  final List<String> likes;
  final List<CommentModel> comments;
  final DateTime createdAt;
  final String location;

  const PostModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.fullName,
    required this.profileImageUrl,
    required this.caption,
    required this.imageUrls,
    this.videoUrls = const [],
    this.mediaType = MediaType.text,
    required this.likes,
    required this.comments,
    required this.createdAt,
    required this.location,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      fullName: map['fullName'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      caption: map['caption'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      videoUrls: List<String>.from(map['videoUrls'] ?? []),
      mediaType: MediaType.values.firstWhere(
        (e) => e.toString() == 'MediaType.${map['mediaType']}',
        orElse: () => MediaType.text,
      ),
      likes: List<String>.from(map['likes'] ?? []),
      comments: (map['comments'] as List? ?? [])
          .map((comment) => CommentModel.fromMap(comment))
          .toList(),
      createdAt: map['createdAt'] ?? DateTime.now(),
      location: map['location'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'username': username,
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
      'caption': caption,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'mediaType': mediaType.toString().split('.').last,
      'likes': likes,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'createdAt': createdAt,
      'location': location,
    };
  }

  PostModel copyWith({
    String? id,
    String? uid,
    String? username,
    String? fullName,
    String? profileImageUrl,
    String? caption,
    List<String>? imageUrls,
    List<String>? videoUrls,
    MediaType? mediaType,
    List<String>? likes,
    List<CommentModel>? comments,
    DateTime? createdAt,
    String? location,
  }) {
    return PostModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      caption: caption ?? this.caption,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      mediaType: mediaType ?? this.mediaType,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
    );
  }

  @override
  List<Object?> get props => [
        id,
        uid,
        username,
        fullName,
        profileImageUrl,
        caption,
        imageUrls,
        videoUrls,
        mediaType,
        likes,
        comments,
        createdAt,
        location,
      ];
}

class CommentModel extends Equatable {
  final String id;
  final String uid;
  final String username;
  final String comment;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.comment,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'username': username,
      'comment': comment,
      'createdAt': createdAt,
    };
  }

  CommentModel copyWith({
    String? id,
    String? uid,
    String? username,
    String? comment,
    DateTime? createdAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, uid, username, comment, createdAt];
}