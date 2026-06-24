import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../repositories/mock_data_service.dart';
import '../../../repositories/user_repository.dart';
import '../../../constants/color_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _userReels = [];
  List<Map<String, dynamic>> _taggedPosts = [];
  List<Map<String, dynamic>> _repostedPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserContent() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      setState(() {
        // Get user's posts
        _userPosts = MockDataService.getUserPosts(authState.user.uid);

        // For demo purposes, simulate reels as posts with video icon
        _userReels = _userPosts.take(2).toList();

        // For demo, simulate tagged posts
        _taggedPosts = MockDataService.getPosts()
            .where((post) => post['uid'] != authState.user.uid)
            .take(3)
            .toList();

        // For demo, simulate reposts
        _repostedPosts = MockDataService.getPosts()
            .where((post) => post['uid'] != authState.user.uid)
            .take(2)
            .toList();
      });

      // Fetch the latest profile data from the backend
      try {
        await context.read<UserRepository>().getProfile();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return Text(
                state.user.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              );
            }
            return const Text('Profile');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: AppColors.onSurface),
            onPressed: () {
              // Create post
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.onSurface),
            onPressed: () {
              // Show menu
              _showProfileMenu(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Profile Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Profile Image and Stats
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Profile Image
                                  GestureDetector(
                                    onTap: () => _showProfileImageZoom(
                                      context,
                                      user.profileImageUrl,
                                      user.fullName,
                                    ),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: AppColors.accent,
                                      backgroundImage:
                                          user.profileImageUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              user.profileImageUrl,
                                            )
                                          : null,
                                      child: user.profileImageUrl.isEmpty
                                          ? Text(
                                              user.fullName.isNotEmpty
                                                  ? user.fullName[0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.onAccent,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  // Stats
                                  _buildStatColumn(
                                    (user.postsCount ?? user.posts.length).toString(),
                                    'Posts',
                                  ),
                                  _buildStatColumn(
                                    (user.followersCount ?? user.followers.length).toString(),
                                    'Followers',
                                  ),
                                  _buildStatColumn(
                                    (user.followingCount ?? user.following.length).toString(),
                                    'Following',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Name and Bio
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (user.bio.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        user.bio,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                    if (user.interests.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: user.interests
                                            .map(
                                              (interest) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.neutral600,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  interest,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Edit Profile and Share Profile Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        context.push('/edit-profile');
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: AppColors.neutral400,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Edit profile',
                                        style: TextStyle(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Share profile
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: AppColors.neutral400,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Share profile',
                                        style: TextStyle(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Tab Bar
                        TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.accent,
                          labelColor: AppColors.accent,
                          unselectedLabelColor: AppColors.neutral400,
                          tabs: const [
                            Tab(icon: Icon(Icons.grid_on)),
                            Tab(
                              icon: Icon(
                                Icons.play_arrow_outlined,
                              ),
                            ),
                            Tab(
                              icon: Icon(
                                Icons.person_pin_outlined,
                              ),
                            ),
                            Tab(
                              icon: Icon(
                                Icons.bookmark_border,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Posts Grid
                  _buildPostsGrid(_userPosts),
                  // Reels Grid
                  _buildReelsGrid(_userReels),
                  // Tagged Grid
                  _buildTaggedGrid(_taggedPosts),
                  // Reposts Grid
                  _buildRepostsGrid(_repostedPosts),
                ],
              ),
            );
          }

          return const Center(
            child: Text('Please log in to view your profile'),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return GestureDetector(
      onTap: () {
        // Navigate to followers/following list
      },
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 14, color: AppColors.neutral200)),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(List<Map<String, dynamic>> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 60, color: AppColors.neutral400),
            SizedBox(height: 16),
            Text(
              'No Posts Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'When you share photos, they will appear on your profile.',
              style: TextStyle(color: AppColors.neutral200),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final imageUrls = post['imageUrls'] as List<dynamic>;
        final imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : '';

        return GestureDetector(
          onTap: () {
            // Navigate to post detail
          },
          child: Container(
            color: AppColors.neutral600,
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.neutral600,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.neutral600,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppColors.neutral500,
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.neutral200,
                    child: const Icon(Icons.image, color: AppColors.neutral500),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildReelsGrid(List<Map<String, dynamic>> reels) {
    if (reels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 60, color: AppColors.neutral400),
            SizedBox(height: 16),
            Text(
              'No Reels Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 16, // Vertical aspect ratio for reels
      ),
      itemCount: reels.length,
      itemBuilder: (context, index) {
        final reel = reels[index];
        final imageUrls = reel['imageUrls'] as List<dynamic>;
        final imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : '';

        return GestureDetector(
          onTap: () {
            // Navigate to reel detail
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: AppColors.neutral600,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.neutral200),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.neutral600,
                          child: const Icon(
                            Icons.video_library,
                            color: AppColors.neutral500,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.neutral600,
                        child: const Icon(
                          Icons.video_library,
                          color: AppColors.neutral500,
                        ),
                      ),
              ),
              // Play icon overlay
              const Positioned(
                bottom: 8,
                left: 8,
                child: Icon(Icons.play_arrow, color: AppColors.onAccent, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaggedGrid(List<Map<String, dynamic>> tagged) {
    if (tagged.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_pin_outlined, size: 60, color: AppColors.neutral400),
            SizedBox(height: 16),
            Text(
              'Photos of you',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'When people tag you in photos, they\'ll appear here.',
              style: TextStyle(color: AppColors.neutral200),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: tagged.length,
      itemBuilder: (context, index) {
        final post = tagged[index];
        final imageUrls = post['imageUrls'] as List<dynamic>;
        final imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : '';

        return GestureDetector(
          onTap: () {
            // Navigate to post detail
          },
          child: Container(
            color: AppColors.neutral600,
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: AppColors.neutral200),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.neutral600,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppColors.neutral500,
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.neutral200,
                    child: const Icon(Icons.image, color: AppColors.neutral500),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRepostsGrid(List<Map<String, dynamic>> reposts) {
    if (reposts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 60, color: AppColors.neutral400),
            SizedBox(height: 16),
            Text(
              'Saved',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Save photos and videos that you want to see again.',
              style: TextStyle(color: AppColors.neutral200),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: reposts.length,
      itemBuilder: (context, index) {
        final post = reposts[index];
        final imageUrls = post['imageUrls'] as List<dynamic>;
        final imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : '';

        return GestureDetector(
          onTap: () {
            // Navigate to post detail
          },
          child: Container(
            color: AppColors.neutral600,
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: AppColors.neutral200),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.neutral600,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppColors.neutral500,
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.neutral200,
                    child: const Icon(Icons.image, color: AppColors.neutral500),
                  ),
          ),
        );
      },
    );
  }

  void _showProfileImageZoom(
    BuildContext context,
    String imageUrl,
    String fullName,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
              ),
              Center(
                child: imageUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 260,
                          height: 260,
                          fit: BoxFit.cover,
                        ),
                      )
                    : CircleAvatar(
                        radius: 130,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onAccent,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.neutral600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_outline),
                title: const Text('Saved'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to saved posts
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Your activity'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to activity
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Archive'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to archive
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('QR code'),
                onTap: () {
                  Navigator.pop(context);
                  // Show QR code
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Log out',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
