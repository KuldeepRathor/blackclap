import 'package:equatable/equatable.dart';

abstract class PostsEvent extends Equatable {
  const PostsEvent();

  @override
  List<Object?> get props => [];
}

class PostsLoadRequested extends PostsEvent {}

class PostsRefreshRequested extends PostsEvent {}

class PostsLikeToggled extends PostsEvent {
  final String postId;
  final String userId;

  const PostsLikeToggled({
    required this.postId,
    required this.userId,
  });

  @override
  List<Object?> get props => [postId, userId];
}

class PostsCreateRequested extends PostsEvent {
  final String uid;
  final String caption;
  final List<String> imageUrls;

  const PostsCreateRequested({
    required this.uid,
    required this.caption,
    required this.imageUrls,
  });

  @override
  List<Object?> get props => [uid, caption, imageUrls];
}