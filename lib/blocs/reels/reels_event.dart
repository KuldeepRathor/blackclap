import 'package:equatable/equatable.dart';

abstract class ReelsEvent extends Equatable {
  const ReelsEvent();

  @override
  List<Object?> get props => [];
}

class ReelsLoadRequested extends ReelsEvent {}

class ReelsLikeToggled extends ReelsEvent {
  final String reelId;
  final String userId;

  const ReelsLikeToggled({required this.reelId, required this.userId});

  @override
  List<Object?> get props => [reelId, userId];
}
