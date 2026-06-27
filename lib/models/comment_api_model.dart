class CommentApiModel {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final String? parentId;
  final int repliesCount;
  final DateTime createdAt;

  const CommentApiModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    this.parentId,
    required this.repliesCount,
    required this.createdAt,
  });

  factory CommentApiModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return CommentApiModel(
      id: json['id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: user['username'] as String? ?? '',
      avatarUrl: user['avatar_url'] as String?,
      content: json['content'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      repliesCount: json['replies_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  CommentApiModel copyWith({int? repliesCount}) => CommentApiModel(
        id: id,
        postId: postId,
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        content: content,
        parentId: parentId,
        repliesCount: repliesCount ?? this.repliesCount,
        createdAt: createdAt,
      );
}
