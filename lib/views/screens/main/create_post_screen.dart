import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../blocs/posts/posts_bloc.dart';
import '../../../blocs/posts/posts_event.dart';
import '../../../blocs/posts/posts_state.dart';
import '../../../constants/color_constants.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── Media picking ───────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 80);
      if (images.isEmpty) return;

      if (images.length > 5) {
        _showError('You can select a maximum of 5 images.');
        return;
      }

      setState(() => _selectedImages = images);
    } catch (e) {
      _showError('Error picking images: $e');
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final photo =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (photo == null) return;

      if (_selectedImages.length >= 5) {
        _showError('You can select a maximum of 5 images.');
        return;
      }

      setState(() => _selectedImages = [..._selectedImages, photo]);
    } catch (e) {
      _showError('Error capturing photo: $e');
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages = List.from(_selectedImages)..removeAt(index));
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMediaOption(
                icon: Icons.photo_library,
                title: 'Choose Images',
                subtitle: 'Pick up to 5 from gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              _buildMediaOption(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Use camera',
                onTap: () {
                  Navigator.pop(context);
                  _capturePhoto();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Post submission ─────────────────────────────────────────────────────────

  void _submitPost() {
    final caption = _captionController.text.trim();
    final location = _locationController.text.trim();

    if (caption.isEmpty && _selectedImages.isEmpty) {
      _showError('Add a caption or select at least one image.');
      return;
    }

    context.read<PostsBloc>().add(
          PostsCreateRequested(
            filePaths: _selectedImages.map((x) => x.path).toList(),
            caption: caption,
            location: location.isEmpty ? null : location,
          ),
        );
  }

  void _resetForm() {
    _captionController.clear();
    _locationController.clear();
    setState(() => _selectedImages = []);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.accent),
      ),
      title: Text(title,
          style: const TextStyle(
              color: AppColors.onSurface, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.neutral300, fontSize: 12)),
      onTap: onTap,
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostsBloc, PostsState>(
      listenWhen: (prev, curr) =>
          curr is PostsCreateSuccess || curr is PostsCreateError,
      listener: (context, state) {
        if (state is PostsCreateSuccess) {
          _showSuccess('Post created successfully!');
          _resetForm();
        } else if (state is PostsCreateError) {
          _showError(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is PostsCreateLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.onSurface),
              onPressed: isLoading ? null : _resetForm,
            ),
            title: const Text(
              'Create Post',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Post',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caption
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _captionController,
                    maxLines: 5,
                    maxLength: 2200,
                    enabled: !isLoading,
                    style: const TextStyle(
                        color: AppColors.onSurface, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Write a caption...',
                      hintStyle:
                          const TextStyle(color: AppColors.neutral400),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.neutral600)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.neutral600)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.accent, width: 2)),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                ),

                // Location
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _locationController,
                    enabled: !isLoading,
                    style: const TextStyle(color: AppColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Add location',
                      hintStyle:
                          const TextStyle(color: AppColors.neutral400),
                      prefixIcon: const Icon(Icons.location_on,
                          color: AppColors.accent),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.neutral600)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.neutral600)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.accent, width: 2)),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Image count badge
                if (_selectedImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.image, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedImages.length} / 5 image${_selectedImages.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                // Image previews
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 250,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.surface,
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(_selectedImages[index].path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              // Upload overlay while loading
                              if (isLoading)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white),
                                  ),
                                ),
                              // Remove button
                              if (!isLoading)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // Add/change media button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    onTap: isLoading ? null : _showMediaOptions,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedImages.isEmpty
                                ? Icons.add_photo_alternate
                                : Icons.edit,
                            color: isLoading
                                ? AppColors.neutral400
                                : AppColors.accent,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedImages.isEmpty
                                ? 'Add Photos'
                                : 'Change Photos',
                            style: TextStyle(
                              color: isLoading
                                  ? AppColors.neutral400
                                  : AppColors.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'You can add up to 5 images per post',
                    style: const TextStyle(
                        color: AppColors.neutral400, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
