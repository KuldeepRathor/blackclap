part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// No active search query — show the browse tabs (posts grid, users grid, trending).
class SearchBrowsing extends SearchState {
  const SearchBrowsing();
}

/// API request in flight for a fresh query.
class SearchLoading extends SearchState {
  final String query;

  const SearchLoading(this.query);

  @override
  List<Object?> get props => [query];
}

/// Results returned successfully for an active query.
class SearchLoaded extends SearchState {
  final String query;

  /// 0 = All, 1 = Users, 2 = Posts
  final int activeTab;

  final List<UserModel> users;
  final List<PostModel> posts;

  /// Cursor for the next page of posts (null = no more posts).
  final String? nextCursor;

  /// Current OFFSET for user pagination.
  final int usersOffset;

  /// True while loading an additional page (spinner at list bottom).
  final bool isLoadingMore;

  final bool hasMorePosts;
  final bool hasMoreUsers;

  const SearchLoaded({
    required this.query,
    this.activeTab = 0,
    this.users = const [],
    this.posts = const [],
    this.nextCursor,
    this.usersOffset = 0,
    this.isLoadingMore = false,
    this.hasMorePosts = false,
    this.hasMoreUsers = true,
  });

  SearchLoaded copyWith({
    String? query,
    int? activeTab,
    List<UserModel>? users,
    List<PostModel>? posts,
    String? nextCursor,
    bool clearNextCursor = false,
    int? usersOffset,
    bool? isLoadingMore,
    bool? hasMorePosts,
    bool? hasMoreUsers,
  }) {
    return SearchLoaded(
      query: query ?? this.query,
      activeTab: activeTab ?? this.activeTab,
      users: users ?? this.users,
      posts: posts ?? this.posts,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      usersOffset: usersOffset ?? this.usersOffset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      hasMoreUsers: hasMoreUsers ?? this.hasMoreUsers,
    );
  }

  @override
  List<Object?> get props => [
        query,
        activeTab,
        users,
        posts,
        nextCursor,
        usersOffset,
        isLoadingMore,
        hasMorePosts,
        hasMoreUsers,
      ];
}

class SearchError extends SearchState {
  final String message;
  final String query;

  const SearchError({required this.message, required this.query});

  @override
  List<Object?> get props => [message, query];
}
