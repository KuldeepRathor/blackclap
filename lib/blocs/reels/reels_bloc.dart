import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/mock_data_service.dart';
import 'reels_event.dart';
import 'reels_state.dart';

class ReelsBloc extends Bloc<ReelsEvent, ReelsState> {
  ReelsBloc() : super(ReelsInitial()) {
    on<ReelsLoadRequested>(_onLoadRequested);
    on<ReelsLikeToggled>(_onLikeToggled);
  }

  Future<void> _onLoadRequested(
    ReelsLoadRequested event,
    Emitter<ReelsState> emit,
  ) async {
    emit(ReelsLoading());
    try {
      final reels = MockDataService.getReels();
      emit(ReelsLoaded(reels: reels));
    } catch (e) {
      emit(ReelsError(message: e.toString()));
    }
  }

  Future<void> _onLikeToggled(
    ReelsLikeToggled event,
    Emitter<ReelsState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is ReelsLoaded) {
        final reel = currentState.reels.firstWhere(
          (r) => r['id'] == event.reelId,
        );

        if ((reel['likes'] as List).contains(event.userId)) {
          await MockDataService.unlikeReel(event.reelId, event.userId);
        } else {
          await MockDataService.likeReel(event.reelId, event.userId);
        }

        final updatedReels = MockDataService.getReels();
        emit(ReelsLoaded(reels: updatedReels));
      }
    } catch (e) {
      emit(ReelsError(message: e.toString()));
    }
  }
}
