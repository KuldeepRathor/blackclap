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

  const PostsLikeToggled({required this.postId, required this.userId});

  @override
  List<Object?> get props => [postId, userId];
}

class PostsCreateRequested extends PostsEvent {
  /// Absolute file paths for each selected image (from XFile.path).
  final List<String> filePaths;
  final String caption;
  final String? location;

  const PostsCreateRequested({
    required this.filePaths,
    required this.caption,
    this.location,
  });

  @override
  List<Object?> get props => [filePaths, caption, location];
}
