import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/forgot_password/forgot_password_cubit.dart';
import '../../../constants/color_constants.dart';
import '../../../repositories/user_repository.dart';
import '../../../utils/theme_colors.dart';

/// Step 2 of password reset: enter the 6-digit code emailed to [email].
class VerifyResetCodeScreen extends StatelessWidget {
  final String email;

  const VerifyResetCodeScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ForgotPasswordCubit(ctx.read<UserRepository>()),
      child: _VerifyResetCodeView(email: email),
    );
  }
}

class _VerifyResetCodeView extends StatefulWidget {
  final String email;

  const _VerifyResetCodeView({required this.email});

  @override
  State<_VerifyResetCodeView> createState() => _VerifyResetCodeViewState();
}

class _VerifyResetCodeViewState extends State<_VerifyResetCodeView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      listener: (context, state) {
        if (state.status == ForgotPasswordStatus.success) {
          context.push(
            '/reset-password',
            extra: {'email': widget.email, 'code': _codeController.text.trim()},
          );
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
                    'Enter code',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit code to ${widget.email}. Enter it below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: context.primaryText),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: '6-digit code',
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.pin_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the code';
                            }
                            if (value.length != 6) {
                              return 'Code must be 6 digits';
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
                                          .verifyCode(
                                            widget.email,
                                            _codeController.text.trim(),
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
                                    'Verify',
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
