import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/mock_data_service.dart';
import 'posts_event.dart';
import 'posts_state.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  PostsBloc() : super(PostsInitial()) {
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
      await MockDataService.createPost(
        uid: event.uid,
        caption: event.caption,
        imageUrls: event.imageUrls,
      );
      emit(PostsCreateSuccess());

      final posts = MockDataService.getPosts();
      emit(PostsLoaded(posts: posts));
    } catch (e) {
      emit(PostsCreateError(message: e.toString()));
    }
  }
}