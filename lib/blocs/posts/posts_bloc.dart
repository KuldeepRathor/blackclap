import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/mock_data_service.dart';
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
      final posts = MockDataService.getPosts();
      emit(PostsLoaded(posts: posts));
    } catch (e) {
      emit(PostsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    PostsRefreshRequested event,
    Emitter<PostsState> emit,
  ) async {
    try {
      final posts = MockDataService.getPosts();
      emit(PostsLoaded(posts: posts));
    } catch (e) {
      emit(PostsError(message: e.toString()));
    }
  }

  Future<void> _onLikeToggled(
    PostsLikeToggled event,
    Emitter<PostsState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is PostsLoaded) {
        final post = currentState.posts.firstWhere(
          (p) => p['id'] == event.postId,
        );

        if ((post['likes'] as List).contains(event.userId)) {
          await MockDataService.unlikePost(event.postId, event.userId);
        } else {
          await MockDataService.likePost(event.postId, event.userId);
        }

        final updatedPosts = MockDataService.getPosts();
        emit(PostsLoaded(posts: updatedPosts));
      }
    } catch (e) {
      emit(PostsError(message: e.toString()));
    }
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
    } catch (e) {
      emit(PostsCreateError(message: e.toString()));
    }
  }
}
