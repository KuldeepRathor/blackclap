import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/search_api_service.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchApiService _searchService;

  // Monotonically incrementing ID to discard stale API responses when a new
  // query starts before the previous one completes.
  int _requestId = 0;

  SearchBloc({SearchApiService? searchService})
      : _searchService =
            searchService ?? SearchApiService(ApiService()),
        super(const SearchBrowsing()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchTabChanged>(_onTabChanged);
    on<SearchPostsNextPageRequested>(_onPostsNextPage);
    on<SearchUsersNextPageRequested>(_onUsersNextPage);
    on<SearchCleared>(_onCleared);
  }

  String _tabIndexToType(int index) => switch (index) {
        1 => 'users',
        2 => 'posts',
        _ => 'all',
      };

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.length < 2) {
      emit(const SearchBrowsing());
      return;
    }

    final activeTab = state is SearchLoaded
        ? (state as SearchLoaded).activeTab
        : 0;

    final requestId = ++_requestId;
    emit(SearchLoading(query));

    try {
      final type = _tabIndexToType(activeTab);
      final result = await _searchService.search(query: query, type: type);

      if (requestId != _requestId) return; // stale — a newer query is in flight

      emit(SearchLoaded(
        query: query,
        activeTab: activeTab,
        users: result.users,
        posts: result.posts,
        nextCursor: result.nextCursor,
        hasMorePosts: result.nextCursor != null,
        hasMoreUsers: result.users.length >= 20,
      ));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(SearchError(message: e.toString(), query: query));
    }
  }

  Future<void> _onTabChanged(
    SearchTabChanged event,
    Emitter<SearchState> emit,
  ) async {
    final current = state;
    if (current is! SearchLoaded) return;
    if (current.activeTab == event.tabIndex) return;

    final requestId = ++_requestId;
    emit(SearchLoading(current.query));

    try {
      final type = _tabIndexToType(event.tabIndex);
      final result = await _searchService.search(
        query: current.query,
        type: type,
      );

      if (requestId != _requestId) return;

      emit(SearchLoaded(
        query: current.query,
        activeTab: event.tabIndex,
        users: result.users,
        posts: result.posts,
        nextCursor: result.nextCursor,
        hasMorePosts: result.nextCursor != null,
        hasMoreUsers: result.users.length >= 20,
      ));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(SearchError(message: e.toString(), query: current.query));
    }
  }

  Future<void> _onPostsNextPage(
    SearchPostsNextPageRequested event,
    Emitter<SearchState> emit,
  ) async {
    final current = state;
    if (current is! SearchLoaded) return;
    if (!current.hasMorePosts || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final result = await _searchService.search(
        query: current.query,
        type: 'posts',
        cursor: current.nextCursor,
      );

      emit(current.copyWith(
        posts: [...current.posts, ...result.posts],
        nextCursor: result.nextCursor,
        clearNextCursor: result.nextCursor == null,
        hasMorePosts: result.nextCursor != null,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onUsersNextPage(
    SearchUsersNextPageRequested event,
    Emitter<SearchState> emit,
  ) async {
    final current = state;
    if (current is! SearchLoaded) return;
    if (!current.hasMoreUsers || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final nextOffset = current.usersOffset + 20;
      final result = await _searchService.search(
        query: current.query,
        type: 'users',
        limit: 20,
        offset: nextOffset,
      );

      emit(current.copyWith(
        users: [...current.users, ...result.users],
        usersOffset: nextOffset,
        hasMoreUsers: result.users.length >= 20,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    _requestId++; // invalidate any in-flight requests
    emit(const SearchBrowsing());
  }
}
