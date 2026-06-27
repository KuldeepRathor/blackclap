import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/posts/posts_bloc.dart';
import '../../../blocs/posts/posts_event.dart';
import '../../../blocs/posts/posts_state.dart';
import '../../../constants/color_constants.dart';
import '../../widgets/feed_post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PostsBloc>().add(PostsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.add_box_outlined, color: AppColors.onSurface),
          tooltip: 'Create post',
          onPressed: () => context.push('/create-post'),
        ),
        title: const Text(
          'Blackclap',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline, color: AppColors.onSurface),
            onPressed: () {},
          ),
          // IconButton(
          //   icon: const Icon(Icons.chat_bubble_outline, color: AppColors.onSurface),
          //   onPressed: () {},
          // ),
        ],
      ),
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          if (state is PostsLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (state is PostsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.neutral400),
                  const SizedBox(height: 16),
                  const Text('Error loading posts',
                      style: TextStyle(fontSize: 18, color: AppColors.onSurface)),
                  const SizedBox(height: 8),
                  Text(state.message,
                      style: const TextStyle(fontSize: 14, color: AppColors.neutral200),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<PostsBloc>().add(PostsLoadRequested()),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is PostsLoaded) {
            if (state.posts.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 64, color: AppColors.neutral400),
                    SizedBox(height: 16),
                    Text('No posts yet', style: TextStyle(fontSize: 18, color: AppColors.onSurface)),
                  ],
                ),
              );
            }

            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final currentUserId =
                    authState is AuthAuthenticated ? authState.user.uid : '';
                final currentUsername =
                    authState is AuthAuthenticated ? authState.user.username : '';
                final currentAvatar =
                    authState is AuthAuthenticated ? authState.user.profileImageUrl : '';

                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async =>
                      context.read<PostsBloc>().add(PostsRefreshRequested()),
                  child: ListView.builder(
                    itemCount: state.posts.length,
                    itemBuilder: (context, index) {
                      final raw = state.posts[index];
                      return FeedPostCard(
                        key: ValueKey(raw['id'] ?? index),
                        post: raw,
                        currentUserId: currentUserId,
                        currentUsername: currentUsername,
                        currentAvatar: currentAvatar,
                      );
                    },
                  ),
                );
              },
            );
          }

          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        },
      ),
    );
  }
}
