import 'package:equatable/equatable.dart';

abstract class ReelsState extends Equatable {
  const ReelsState();

  @override
  List<Object?> get props => [];
}

class ReelsInitial extends ReelsState {}

class ReelsLoading extends ReelsState {}

class ReelsLoaded extends ReelsState {
  final List<Map<String, dynamic>> reels;

  const ReelsLoaded({required this.reels});

  @override
  List<Object?> get props => [reels];
}

class ReelsError extends ReelsState {
  final String message;

  const ReelsError({required this.message});

  @override
  List<Object?> get props => [message];
}
