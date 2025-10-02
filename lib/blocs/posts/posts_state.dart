import 'package:equatable/equatable.dart';

abstract class PostsState extends Equatable {
  const PostsState();

  @override
  List<Object?> get props => [];
}

class PostsInitial extends PostsState {}

class PostsLoading extends PostsState {}

class PostsLoaded extends PostsState {
  final List<Map<String, dynamic>> posts;

  const PostsLoaded({required this.posts});

  @override
  List<Object?> get props => [posts];
}

class PostsError extends PostsState {
  final String message;

  const PostsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PostsCreateLoading extends PostsState {}

class PostsCreateSuccess extends PostsState {}

class PostsCreateError extends PostsState {
  final String message;

  const PostsCreateError({required this.message});

  @override
  List<Object?> get props => [message];
}