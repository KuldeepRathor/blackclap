import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/posts/posts_bloc.dart';
import '../../../blocs/posts/posts_event.dart';
import '../../../blocs/posts/posts_state.dart';
import '../../../constants/color_constants.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/search_api_service.dart';

enum _PostMode { image, video }

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final PageController _previewController = PageController();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _pulseController;

  _PostMode _mode = _PostMode.image;
  List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  Uint8List? _videoThumbnail;
  File? _thumbnailFile;
  bool _generatingThumbnail = false;
  int _currentPreviewPage = 0;
  bool _showLocationField = false;
  List<UserModel> _taggedUsers = [];

  final SearchApiService _searchApi = SearchApiService(ApiService());

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _previewController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Mode ──────────────────────────────────────────────────────────────────────

  void _switchMode(_PostMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _selectedImages = [];
      _selectedVideo = null;
      _videoThumbnail = null;
      _thumbnailFile = null;
      _generatingThumbnail = false;
      _currentPreviewPage = 0;
    });
  }

  // ── Image picking ─────────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 80);
      if (images.isEmpty) return;
      final combined = [..._selectedImages, ...images];
      if (combined.length > 5) {
        final remaining = 5 - _selectedImages.length;
        if (remaining <= 0) {
          _showError('You can select a maximum of 5 images.');
          return;
        }
        _showError('Only $remaining slot${remaining == 1 ? '' : 's'} left — added first $remaining.');
      }
      final toAdd = combined.take(5).toList();
      setState(() {
        _selectedImages = toAdd;
        _currentPreviewPage = _selectedImages.length - 1;
      });
      if (_previewController.hasClients) {
        _previewController.jumpToPage(_selectedImages.length - 1);
      }
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
    setState(() {
      _selectedImages = List.from(_selectedImages)..removeAt(index);
      if (_currentPreviewPage >= _selectedImages.length &&
          _currentPreviewPage > 0) {
        _currentPreviewPage = _selectedImages.length - 1;
      }
    });
  }

  // ── Video picking ─────────────────────────────────────────────────────────────

  Future<void> _pickVideo() async {
    try {
      final video = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5));
      if (video == null) return;
      await _setVideo(video);
    } catch (e) {
      _showError('Error picking video: $e');
    }
  }

  Future<void> _recordVideo() async {
    try {
      final video = await _picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 5));
      if (video == null) return;
      await _setVideo(video);
    } catch (e) {
      _showError('Error recording video: $e');
    }
  }

  Future<void> _setVideo(XFile video) async {
    setState(() {
      _selectedVideo = video;
      _videoThumbnail = null;
      _thumbnailFile = null;
      _generatingThumbnail = true;
    });
    await _generateThumbnail(video.path);
  }

  Future<void> _generateThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );
      if (!mounted) return;
      if (thumbPath != null) {
        final thumbFile = File(thumbPath);
        final thumbBytes = await thumbFile.readAsBytes();
        setState(() {
          _thumbnailFile = thumbFile;
          _videoThumbnail = thumbBytes;
          _generatingThumbnail = false;
        });
      } else {
        setState(() => _generatingThumbnail = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generatingThumbnail = false);
        _showError('Could not generate thumbnail: $e');
      }
    }
  }

  void _removeVideo() => setState(() {
        _selectedVideo = null;
        _videoThumbnail = null;
        _thumbnailFile = null;
        _generatingThumbnail = false;
      });

  // ── Submission ────────────────────────────────────────────────────────────────

  void _submitPost() {
    final caption = _captionController.text.trim();
    final location = _locationController.text.trim();
    final taggedIds = _taggedUsers.map((u) => u.uid).toList();

    if (_mode == _PostMode.video) {
      if (_selectedVideo == null) {
        _showError('Please select a video.');
        return;
      }
      if (_generatingThumbnail) {
        _showError('Please wait, generating thumbnail…');
        return;
      }
      context.read<PostsBloc>().add(PostsCreateRequested(
            filePaths: [_selectedVideo!.path],
            caption: caption,
            location: location.isEmpty ? null : location,
            mediaType: 'video',
            thumbnailPath: _thumbnailFile?.path,
            taggedUserIds: taggedIds,
          ));
    } else {
      if (caption.isEmpty && _selectedImages.isEmpty) {
        _showError('Add a caption or select at least one image.');
        return;
      }
      context.read<PostsBloc>().add(PostsCreateRequested(
            filePaths: _selectedImages.map((x) => x.path).toList(),
            caption: caption,
            location: location.isEmpty ? null : location,
            mediaType: _selectedImages.isEmpty ? 'text' : 'image',
            taggedUserIds: taggedIds,
          ));
    }
  }

  void _resetForm() {
    _captionController.clear();
    _locationController.clear();
    setState(() {
      _selectedImages = [];
      _selectedVideo = null;
      _videoThumbnail = null;
      _thumbnailFile = null;
      _generatingThumbnail = false;
      _currentPreviewPage = 0;
      _showLocationField = false;
      _taggedUsers = [];
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  bool get _hasMedia =>
      (_mode == _PostMode.image && _selectedImages.isNotEmpty) ||
      (_mode == _PostMode.video && _selectedVideo != null);

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostsBloc, PostsState>(
      listenWhen: (prev, curr) =>
          curr is PostsCreateSuccess || curr is PostsCreateError,
      listener: (context, state) {
        if (state is PostsCreateSuccess) {
          _showSuccess('Post shared!');
          _resetForm();
        } else if (state is PostsCreateError) {
          _showError(state.message);
        }
      },
      builder: (context, postsState) {
        final isLoading = postsState is PostsCreateLoading;

        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final username = authState is AuthAuthenticated
                ? authState.user.username
                : 'you';
            final avatarUrl = authState is AuthAuthenticated
                ? authState.user.profileImageUrl
                : '';

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: _buildAppBar(isLoading),
              body: Stack(
                children: [
                  Column(
                    children: [
                      _buildModeToggle(isLoading),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMediaArea(isLoading),
                              _buildCaptionSection(
                                  username, avatarUrl, isLoading),
                              const Divider(
                                  height: 1, color: AppColors.neutral600),
                              _buildLocationRow(isLoading),
                              const Divider(
                                  height: 1, color: AppColors.neutral600),
                              _buildTagPeopleRow(isLoading),
                              const Divider(
                                  height: 1, color: AppColors.neutral600),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomBar(isLoading),
                  ),
                  if (isLoading) _buildLoadingOverlay(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isLoading) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.onSurface, size: 20),
        onPressed: isLoading
            ? null
            : () {
                _resetForm();
                Navigator.of(context).pop();
              },
      ),
      title: const Text(
        'New Post',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: AppColors.onSurface,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: isLoading ? null : _submitPost,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLoading
                      ? [AppColors.neutral600, AppColors.neutral600]
                      : [AppColors.accent, AppColors.accentBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Share',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mode toggle ───────────────────────────────────────────────────────────────

  Widget _buildModeToggle(bool isLoading) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              label: 'Photos',
              icon: Icons.photo_library_outlined,
              isSelected: _mode == _PostMode.image,
              onTap: isLoading ? null : () => _switchMode(_PostMode.image),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeChip(
              label: 'Video',
              icon: Icons.videocam_outlined,
              isSelected: _mode == _PostMode.video,
              onTap: isLoading ? null : () => _switchMode(_PostMode.video),
            ),
          ),
        ],
      ),
    );
  }

  // ── Media area ────────────────────────────────────────────────────────────────

  Widget _buildMediaArea(bool isLoading) {
    final size = MediaQuery.of(context).size.width;

    if (_mode == _PostMode.image) {
      return _selectedImages.isEmpty
          ? _buildEmptyMedia(size, isLoading)
          : _buildImagePreview(size, isLoading);
    } else {
      return _selectedVideo == null
          ? _buildEmptyMedia(size, isLoading)
          : _buildVideoPreview(size, isLoading);
    }
  }

  Widget _buildEmptyMedia(double size, bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _showMediaOptions,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) {
          final pulse = _pulseController.value;
          return SizedBox(
            height: size,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: AppColors.surface),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.08 + pulse * 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withValues(alpha: 0.15 + pulse * 0.1),
                              AppColors.accentBlue
                                  .withValues(alpha: 0.15 + pulse * 0.1),
                            ],
                          ),
                          border: Border.all(
                            color:
                                AppColors.accent.withValues(alpha: 0.3 + pulse * 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _mode == _PostMode.image
                              ? Icons.add_photo_alternate_outlined
                              : Icons.video_call_outlined,
                          color: AppColors.accent.withValues(alpha: 0.6 + pulse * 0.4),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _mode == _PostMode.image
                            ? 'Add Photos'
                            : 'Add Video',
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _mode == _PostMode.image
                            ? 'Gallery or camera · up to 5 photos'
                            : 'Gallery or camera · up to 5 minutes',
                        style: const TextStyle(
                          color: AppColors.neutral400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePreview(double size, bool isLoading) {
    return SizedBox(
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _previewController,
            itemCount: _selectedImages.length,
            onPageChanged: (i) => setState(() => _currentPreviewPage = i),
            itemBuilder: (_, i) => Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: Colors.black,
                  child: Image.file(
                    File(_selectedImages[i].path),
                    fit: BoxFit.contain,
                  ),
                ),
                if (!isLoading)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _removeImage(i),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Counter badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      color: Colors.white, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    '${_currentPreviewPage + 1} / ${_selectedImages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Dot indicators
          if (_selectedImages.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _selectedImages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPreviewPage == i ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _currentPreviewPage == i
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(double size, bool isLoading) {
    return SizedBox(
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          if (_generatingThumbnail)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  SizedBox(height: 14),
                  Text('Generating preview…',
                      style: TextStyle(
                          color: AppColors.neutral400, fontSize: 13)),
                ],
              ),
            )
          else if (_videoThumbnail != null)
            Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(_videoThumbnail!, fit: BoxFit.contain),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 2),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 40),
                  ),
                ),
              ],
            )
          else
            const Center(
              child: Icon(Icons.videocam_outlined,
                  color: AppColors.neutral500, size: 72),
            ),
          // Video label
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text('Video',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          if (!isLoading && !_generatingThumbnail)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _removeVideo,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Caption ───────────────────────────────────────────────────────────────────

  Widget _buildCaptionSection(
      String username, String avatarUrl, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent,
            backgroundImage: avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onAccent,
                        fontSize: 16),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _captionController,
                  maxLines: null,
                  maxLength: 2200,
                  enabled: !isLoading,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    height: 1.45,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Write a caption…',
                    hintStyle:
                        TextStyle(color: AppColors.neutral400, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterStyle:
                        TextStyle(color: AppColors.neutral400, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Location ──────────────────────────────────────────────────────────────────

  Widget _buildLocationRow(bool isLoading) {
    return InkWell(
      onTap: isLoading
          ? null
          : () => setState(() {
                _showLocationField = !_showLocationField;
              }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined,
                color: AppColors.neutral400, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: _showLocationField
                  ? TextField(
                      controller: _locationController,
                      autofocus: true,
                      enabled: !isLoading,
                      style: const TextStyle(
                          color: AppColors.onSurface, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Add location…',
                        hintStyle: TextStyle(color: AppColors.neutral400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : Text(
                      _locationController.text.isNotEmpty
                          ? _locationController.text
                          : 'Add location',
                      style: TextStyle(
                        color: _locationController.text.isNotEmpty
                            ? AppColors.onSurface
                            : AppColors.neutral400,
                        fontSize: 15,
                      ),
                    ),
            ),
            Icon(
              _showLocationField
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.chevron_right_rounded,
              color: AppColors.neutral500,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tag people ────────────────────────────────────────────────────────────────

  Widget _buildTagPeopleRow(bool isLoading) {
    return InkWell(
      onTap: isLoading ? null : _showTagPeopleSheet,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_add_alt_1_outlined,
                    color: AppColors.neutral400, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _taggedUsers.isEmpty ? 'Tag people' : 'Tagged people',
                    style: TextStyle(
                      color: _taggedUsers.isEmpty
                          ? AppColors.neutral400
                          : AppColors.onSurface,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.neutral500,
                  size: 22,
                ),
              ],
            ),
            if (_taggedUsers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _taggedUsers.map((user) {
                  return Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.accent,
                      backgroundImage: user.profileImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(user.profileImageUrl)
                          : null,
                      child: user.profileImageUrl.isEmpty
                          ? Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.onAccent,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    label: Text(
                      '@${user.username}',
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    deleteIcon: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.accent),
                    onDeleted: isLoading
                        ? null
                        : () => setState(
                            () => _taggedUsers.removeWhere(
                                (u) => u.uid == user.uid)),
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTagPeopleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TagPeopleSheet(
        searchApi: _searchApi,
        alreadyTagged: List.from(_taggedUsers),
        onTagsChanged: (updated) => setState(() => _taggedUsers = updated),
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool isLoading) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(color: AppColors.neutral600, width: 0.5)),
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          if (_mode == _PostMode.image) ...[
            _BottomAction(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onTap: isLoading ? null : _pickImages,
            ),
            _BottomAction(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              onTap: isLoading ? null : _capturePhoto,
            ),
          ] else ...[
            _BottomAction(
              icon: Icons.video_library_outlined,
              label: 'Gallery',
              onTap: isLoading ? null : _pickVideo,
            ),
            _BottomAction(
              icon: Icons.videocam_outlined,
              label: 'Record',
              onTap: isLoading ? null : _recordVideo,
            ),
          ],
          const Spacer(),
          if (_hasMedia)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _mode == _PostMode.image
                    ? '${_selectedImages.length} / 5'
                    : '1 video',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Loading overlay ───────────────────────────────────────────────────────────

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sharing your post…',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Media options sheet ───────────────────────────────────────────────────────

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.neutral500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ...(_mode == _PostMode.image
                  ? [
                      _mediaOption(
                        icon: Icons.photo_library_outlined,
                        label: 'Choose from gallery',
                        sub: 'Up to 5 photos',
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImages();
                        },
                      ),
                      _mediaOption(
                        icon: Icons.camera_alt_outlined,
                        label: 'Take a photo',
                        sub: 'Use camera',
                        onTap: () {
                          Navigator.pop(ctx);
                          _capturePhoto();
                        },
                      ),
                    ]
                  : [
                      _mediaOption(
                        icon: Icons.video_library_outlined,
                        label: 'Choose from gallery',
                        sub: 'Up to 5 minutes',
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickVideo();
                        },
                      ),
                      _mediaOption(
                        icon: Icons.videocam_outlined,
                        label: 'Record a video',
                        sub: 'Use camera',
                        onTap: () {
                          Navigator.pop(ctx);
                          _recordVideo();
                        },
                      ),
                    ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaOption({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.accent, size: 22),
      ),
      title: Text(label,
          style: const TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 15)),
      subtitle: Text(sub,
          style:
              const TextStyle(color: AppColors.neutral400, fontSize: 12)),
      onTap: onTap,
    );
  }
}

// ── Mode Chip ──────────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 17,
                color: isSelected ? Colors.white : AppColors.neutral400),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.neutral400,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tag People Sheet ───────────────────────────────────────────────────────────

class _TagPeopleSheet extends StatefulWidget {
  final SearchApiService searchApi;
  final List<UserModel> alreadyTagged;
  final ValueChanged<List<UserModel>> onTagsChanged;

  const _TagPeopleSheet({
    required this.searchApi,
    required this.alreadyTagged,
    required this.onTagsChanged,
  });

  @override
  State<_TagPeopleSheet> createState() => _TagPeopleSheetState();
}

class _TagPeopleSheetState extends State<_TagPeopleSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _results = [];
  List<UserModel> _tagged = [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tagged = List.from(widget.alreadyTagged);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _search(q);
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final result = await widget.searchApi.search(query: query, type: 'users', limit: 20);
      if (mounted && _searchController.text.trim() == query) {
        setState(() => _results = result.users);
      }
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle(UserModel user) {
    setState(() {
      final existing = _tagged.indexWhere((u) => u.uid == user.uid);
      if (existing >= 0) {
        _tagged.removeAt(existing);
      } else {
        _tagged.add(user);
      }
    });
  }

  void _done() {
    widget.onTagsChanged(_tagged);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle + header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tag people',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _done,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, AppColors.accentBlue],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Done${_tagged.isNotEmpty ? ' (${_tagged.length})' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.neutral700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                          color: AppColors.onSurface, fontSize: 15),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppColors.neutral400, size: 20),
                        hintText: 'Search users…',
                        hintStyle: TextStyle(
                            color: AppColors.neutral400, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tagged chips
            if (_tagged.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tagged.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final u = _tagged[i];
                    return Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor:
                          AppColors.accent.withValues(alpha: 0.12),
                      avatar: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.accent,
                        backgroundImage: u.profileImageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(u.profileImageUrl)
                            : null,
                        child: u.profileImageUrl.isEmpty
                            ? Text(
                                u.username.isNotEmpty
                                    ? u.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.onAccent,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      label: Text('@${u.username}',
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      deleteIcon: const Icon(Icons.close_rounded,
                          size: 14, color: AppColors.accent),
                      onDeleted: () => _toggle(u),
                      padding: EdgeInsets.zero,
                    );
                  },
                ),
              ),
            const Divider(height: 1, color: AppColors.neutral600),
            // Results list
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent))
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Search to tag someone'
                                : 'No users found',
                            style: const TextStyle(
                                color: AppColors.neutral400, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _results.length,
                          itemBuilder: (_, i) {
                            final user = _results[i];
                            final isTagged =
                                _tagged.any((u) => u.uid == user.uid);
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.accent,
                                backgroundImage:
                                    user.profileImageUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            user.profileImageUrl)
                                        : null,
                                child: user.profileImageUrl.isEmpty
                                    ? Text(
                                        user.username.isNotEmpty
                                            ? user.username[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.onAccent),
                                      )
                                    : null,
                              ),
                              title: Text(
                                user.username,
                                style: const TextStyle(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: user.fullName.isNotEmpty
                                  ? Text(user.fullName,
                                      style: const TextStyle(
                                          color: AppColors.neutral400,
                                          fontSize: 13))
                                  : null,
                              trailing: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isTagged
                                      ? AppColors.accent
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isTagged
                                        ? AppColors.accent
                                        : AppColors.neutral400,
                                    width: 2,
                                  ),
                                ),
                                child: isTagged
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 16)
                                    : null,
                              ),
                              onTap: () => _toggle(user),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

// ── Bottom Action ──────────────────────────────────────────────────────────────

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? AppColors.onSurface : AppColors.neutral500,
                size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.neutral200 : AppColors.neutral500,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
