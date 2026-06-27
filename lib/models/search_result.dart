import 'package:equatable/equatable.dart';
import 'post_model.dart';
import 'user_model.dart';

class SearchResult extends Equatable {
  final List<UserModel> users;
  final List<PostModel> posts;
  final String? nextCursor;

  const SearchResult({
    this.users = const [],
    this.posts = const [],
    this.nextCursor,
  });

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      users: (map['users'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(UserModel.fromMap)
          .toList(),
      posts: (map['posts'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(PostModel.fromApiResponse)
          .toList(),
      nextCursor: map['next_cursor'] as String?,
    );
  }

  @override
  List<Object?> get props => [users, posts, nextCursor];
}
