import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/post_repository.dart';
import 'posts_event.dart';
import 'posts_state.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final PostRepository _postRepository;

  PostsBloc({required PostRepository postRepository})
      : _postRepository = postRepository,
        super(PostsInitial()) {
    on<PostsLoadRequested>(_onLoadRequested);
    on<PostsRefreshRequested>(_onRefreshRequested);
    on<PostsLikeToggled>(_onLikeToggled);
    on<PostsCreateRequested>(_onCreateRequested);
  }

  Future<void> _onLoadRequested(
    PostsLoadRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(PostsLoading());
    try {
      final posts = await _postRepository.getPosts();
      emit(PostsLoaded(posts: posts.map((p) => p.toMap()).toList()));
    } catch (e) {
      emit(PostsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    PostsRefreshRequested event,
    Emitter<PostsState> emit,
  ) async {
    try {
      final posts = await _postRepository.getPosts();
      emit(PostsLoaded(posts: posts.map((p) => p.toMap()).toList()));
    } catch (e) {
      emit(PostsError(message: e.toString()));
    }
  }

  Future<void> _onLikeToggled(
    PostsLikeToggled event,
    Emitter<PostsState> emit,
  ) async {
    // Like toggling is handled optimistically in _FeedPostCard via InteractionApiService.
  }

  Future<void> _onCreateRequested(
    PostsCreateRequested event,
    Emitter<PostsState> emit,
  ) async {
    emit(PostsCreateLoading());
    try {
      if (event.mediaType == 'video') {
        await _postRepository.createVideoPost(
          videoFile: File(event.filePaths.first),
          thumbnailFile: event.thumbnailPath != null ? File(event.thumbnailPath!) : null,
          caption: event.caption,
          location: event.location,
        );
      } else {
        await _postRepository.createPost(
          imageFiles: event.filePaths.map((p) => File(p)).toList(),
          caption: event.caption,
          location: event.location,
        );
      }
      emit(PostsCreateSuccess());
      // The feed shares this bloc, so leaving it on PostsCreateSuccess strands
      // FeedScreen's BlocBuilder on its default (infinite spinner) branch.
      // Re-fetch so the new post shows and the bloc returns to a list state.
      try {
        final posts = await _postRepository.getPosts();
        emit(PostsLoaded(posts: posts.map((p) => p.toMap()).toList()));
      } catch (_) {
        // Refresh failed — leave success state; the feed reloads on next open
        // or pull-to-refresh rather than surfacing a misleading error.
      }
    } catch (e) {
      emit(PostsCreateError(message: e.toString()));
    }
  }
}
