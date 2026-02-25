import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/posts/posts_bloc.dart';
import '../../../blocs/posts/posts_event.dart';
import '../../../blocs/posts/posts_state.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';
import '../../../repositories/mock_data_service.dart';
import '../../widgets/gradient_story_ring.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/post_card.dart';
import '../main/story_viewer_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final Set<String> _viewedStories = {};
  final Set<String> _savedPosts = {};
  List<Map<String, dynamic>> _stories = [];

  @override
  void initState() {
    super.initState();
    context.read<PostsBloc>().add(PostsLoadRequested());
    _stories = MockDataService.getStories();

    // Load saved posts for current user
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final savedIds = MockDataService.getSavedPosts(authState.user.uid);
      setState(() => _savedPosts.addAll(savedIds));
    }
  }

  Future<void> _toggleSave(String postId) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final uid = authState.user.uid;

    setState(() {
      if (_savedPosts.contains(postId)) {
        _savedPosts.remove(postId);
      } else {
        _savedPosts.add(postId);
      }
    });

    if (_savedPosts.contains(postId)) {
      await MockDataService.savePost(postId, uid);
    } else {
      await MockDataService.unsavePost(postId, uid);
    }
  }

  Widget _buildStoriesRow() {
    if (_stories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];
          final uid = story['uid'] as String;
          final username = story['username'] as String;
          final profileImageUrl = story['profileImageUrl'] as String?;
          final isViewed = _viewedStories.contains(uid);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientStoryRing(
                  imageUrl: profileImageUrl,
                  fallbackName: username,
                  radius: 28,
                  isViewed: isViewed,
                  onTap: () {
                    setState(() => _viewedStories.add(uid));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(initialIndex: index),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 62,
                  child: Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Blackclap',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/messages'),
          ),
        ],
      ),
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          if (state is PostsLoading) {
            return ListView(
              children: [
                _buildStoriesRow(),
                ...List.generate(3, (_) => const PostCardShimmer()),
              ],
            );
          }

          if (state is PostsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.neutral400),
                  const SizedBox(height: 16),
                  const Text('Error loading posts',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(state.message,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<PostsBloc>().add(PostsLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is PostsLoaded) {
            if (state.posts.isEmpty) {
              return Column(
                children: [
                  _buildStoriesRow(),
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 64, color: AppColors.neutral400),
                          SizedBox(height: 16),
                          Text('No posts yet', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async {
                context.read<PostsBloc>().add(PostsRefreshRequested());
                _stories = MockDataService.getStories();
                setState(() {});
              },
              child: ListView.builder(
                itemCount: state.posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildStoriesRow();
                  final post = state.posts[index - 1];
                  final postId = post['id'] as String;
                  return PostCard(
                    post: post,
                    isSaved: _savedPosts.contains(postId),
                    onSaveToggle: () => _toggleSave(postId),
                  );
                },
              ),
            );
          }

          return const Center(
              child: CircularProgressIndicator(
            color: AppColors.accent,
          ));
        },
      ),
    );
  }
}
