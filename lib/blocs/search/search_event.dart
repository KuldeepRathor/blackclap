part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class SearchTabChanged extends SearchEvent {
  /// 0 = All, 1 = Users, 2 = Posts
  final int tabIndex;

  const SearchTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class SearchPostsNextPageRequested extends SearchEvent {
  const SearchPostsNextPageRequested();
}

class SearchUsersNextPageRequested extends SearchEvent {
  const SearchUsersNextPageRequested();
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}
