import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../repositories/user_repository.dart';
import '../../../constants/color_constants.dart';
import '../../../utils/theme_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;

  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _temporaryAvatarUrl;

  Future<void> _refreshProfile() async {
    final userRepository = context.read<UserRepository>();
    try {
      final user = await userRepository.getProfile();
      if (user != null && mounted) {
        setState(() {
          _fullNameController.text = user.fullName;
          _usernameController.text = user.username;
          _bioController.text = user.bio;
          _emailController.text = user.email;
          _temporaryAvatarUrl = user.profileImageUrl;
        });
        if (mounted) {
          context.read<AuthBloc>().add(AuthUserChanged(user: user));
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _fullNameController = TextEditingController(text: user.fullName);
      _usernameController = TextEditingController(text: user.username);
      _bioController = TextEditingController(text: user.bio);
      _emailController = TextEditingController(text: user.email);
      _temporaryAvatarUrl = user.profileImageUrl;
    } else {
      _fullNameController = TextEditingController();
      _usernameController = TextEditingController();
      _bioController = TextEditingController();
      _emailController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final userRepository = context.read<UserRepository>();
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final downloadUrl = await userRepository.uploadAvatar(pickedFile.path);

      setState(() {
        _temporaryAvatarUrl = downloadUrl;
        _isUploadingImage = false;
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Profile image uploaded successfully!')),
      );
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final userRepository = context.read<UserRepository>();

    setState(() {
      _isSaving = true;
    });

    try {
      await userRepository.updateProfile(
        displayName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        email: _emailController.text.trim(),
        avatarUrl: _temporaryAvatarUrl,
      );

      setState(() {
        _isSaving = false;
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      navigator.pop();
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('Unauthorized')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: context.primaryText),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Edit profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: context.primaryText,
              ),
            ),
            actions: [
              IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    : const Icon(Icons.check, color: AppColors.accent),
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: RefreshIndicator(
              onRefresh: _refreshProfile,
              color: AppColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                children: [
                  const SizedBox(height: 24),
                  
                  // Profile Photo Picker
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.accent,
                              backgroundImage: _temporaryAvatarUrl != null &&
                                      _temporaryAvatarUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(_temporaryAvatarUrl!)
                                  : null,
                              child: _temporaryAvatarUrl == null ||
                                      _temporaryAvatarUrl!.isEmpty
                                  ? Text(
                                      _fullNameController.text.isNotEmpty
                                          ? _fullNameController.text[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onAccent,
                                      ),
                                    )
                                  : null,
                            ),
                            if (_isUploadingImage)
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _isUploadingImage ? null : _pickAndUploadImage,
                          child: const Text(
                            'Edit picture',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Full Name input
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Username input
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      // Matches only letters, numbers, and underscores (API restriction)
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                        return 'Only letters, numbers, and underscores allowed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Bio input
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      prefixIcon: Icon(Icons.description_outlined),
                      helperText: 'Max 150 characters',
                    ),
                    maxLines: 3,
                    maxLength: 150,
                    buildCounter: (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) {
                      return Text(
                        '$currentLength / $maxLength',
                        style: TextStyle(
                          fontSize: 12,
                          color: currentLength > maxLength!
                              ? AppColors.error
                              : AppColors.neutral200,
                        ),
                      );
                    },
                    validator: (value) {
                      if (value != null && value.length > 150) {
                        return 'Bio cannot exceed 150 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email input
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),         // closes Column
            ),           // closes SingleChildScrollView
          ),             // closes RefreshIndicator
        ),               // closes Form
        );               // closes Scaffold
      },
    );
  }
}
