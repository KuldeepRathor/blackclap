import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';
import '../../../repositories/mock_data_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  File? _newProfileImage;
  String _currentProfileImageUrl = '';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _fullNameController.text = user.fullName;
      _usernameController.text = user.username;
      _bioController.text = user.bio;
      _currentProfileImageUrl = user.profileImageUrl;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _newProfileImage = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      await MockDataService.updateUser(authState.user.uid, {
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
      });
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile photo picker
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.accentSurface,
                  backgroundImage: _newProfileImage != null
                      ? FileImage(_newProfileImage!) as ImageProvider
                      : (_currentProfileImageUrl.isNotEmpty
                          ? NetworkImage(_currentProfileImageUrl)
                          : null),
                  child: _newProfileImage == null &&
                          _currentProfileImageUrl.isEmpty
                      ? const Icon(Icons.person,
                          size: 50, color: AppColors.accent)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: -4,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: AppColors.textOnAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _pickProfileImage,
              child: const Text(
                'Change Profile Photo',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Fields
          _buildField(
            label: 'Full name',
            controller: _fullNameController,
            hint: 'Your display name',
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Username',
            controller: _usernameController,
            hint: 'Your unique username',
            prefix: '@',
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Bio',
            controller: _bioController,
            hint: 'Tell people about yourself...',
            maxLines: 4,
            maxLength: 150,
          ),
          const SizedBox(height: 16),

          // Email (read only)
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final email = state is AuthAuthenticated ? state.user.email : '';
              return _buildField(
                label: 'Email',
                controller: TextEditingController(text: email),
                hint: 'email',
                enabled: false,
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? prefix,
    int maxLines = 1,
    int? maxLength,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.textTertiary, fontSize: 14),
            prefixText: prefix,
            prefixStyle: const TextStyle(color: AppColors.accent),
            filled: true,
            fillColor:
                enabled ? AppColors.surfaceVariant : AppColors.neutral100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neutral300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neutral300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neutral200),
            ),
          ),
        ),
      ],
    );
  }
}
