import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/user_repository.dart';

/// Drives the 3-step OTP password-reset flow (request code → verify code →
/// set new password). Kept separate from AuthBloc since the reset flow never
/// produces an authenticated user. A fresh instance is provided per screen.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final UserRepository _userRepository;

  ForgotPasswordCubit(this._userRepository)
      : super(const ForgotPasswordState());

  Future<void> requestCode(String email) async {
    emit(state.copyWith(status: ForgotPasswordStatus.loading, clearError: true));
    try {
      await _userRepository.requestPasswordReset(email);
      emit(state.copyWith(status: ForgotPasswordStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        error: _clean(e),
      ));
    }
  }

  Future<void> verifyCode(String email, String code) async {
    emit(state.copyWith(status: ForgotPasswordStatus.loading, clearError: true));
    try {
      await _userRepository.verifyResetCode(email, code);
      emit(state.copyWith(status: ForgotPasswordStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        error: _clean(e),
      ));
    }
  }

  Future<void> resetPassword(
      String email, String code, String newPassword) async {
    emit(state.copyWith(status: ForgotPasswordStatus.loading, clearError: true));
    try {
      await _userRepository.confirmPasswordReset(email, code, newPassword);
      emit(state.copyWith(status: ForgotPasswordStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        error: _clean(e),
      ));
    }
  }

  String _clean(Object e) => e.toString().replaceAll('Exception: ', '');
}

enum ForgotPasswordStatus { initial, loading, success, failure }

class ForgotPasswordState extends Equatable {
  final ForgotPasswordStatus status;
  final String? error;

  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.error,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, error];
}
