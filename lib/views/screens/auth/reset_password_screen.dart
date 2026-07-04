import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/forgot_password/forgot_password_cubit.dart';
import '../../../constants/color_constants.dart';
import '../../../repositories/user_repository.dart';
import '../../../utils/theme_colors.dart';

/// Step 3 of password reset: set a new password using the verified [code].
class ResetPasswordScreen extends StatelessWidget {
  final String email;
  final String code;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ForgotPasswordCubit(ctx.read<UserRepository>()),
      child: _ResetPasswordView(email: email, code: code),
    );
  }
}

class _ResetPasswordView extends StatefulWidget {
  final String email;
  final String code;

  const _ResetPasswordView({required this.email, required this.code});

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      listener: (context, state) {
        if (state.status == ForgotPasswordStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset. Please log in with your new password.'),
            ),
          );
          context.go('/login');
        } else if (state.status == ForgotPasswordStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'Something went wrong')),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == ForgotPasswordStatus.loading;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.primaryText),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Text(
                    'New password',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a new password for your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: context.primaryText),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'New password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmController,
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_outlined),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      context
                                          .read<ForgotPasswordCubit>()
                                          .resetPassword(
                                            widget.email,
                                            widget.code,
                                            _passwordController.text,
                                          );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.onAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: AppColors.onAccent,
                                  )
                                : const Text(
                                    'Reset password',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
