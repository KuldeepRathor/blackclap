import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../constants/color_constants.dart';
import '../../../models/post_model.dart';
import '../../widgets/post_card.dart';

class PostDetailScreen extends StatelessWidget {
  final PostModel post;
  final void Function(bool isLiked, int likesCount)? onLikeChanged;

  const PostDetailScreen({super.key, required this.post, this.onLikeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final currentUserId =
              authState is AuthAuthenticated ? authState.user.uid : '';
          final username = authState is AuthAuthenticated
              ? authState.user.username
              : null;
          final avatarUrl = authState is AuthAuthenticated
              ? authState.user.profileImageUrl
              : null;

          return SingleChildScrollView(
            child: PostCard(
              post: post,
              currentUserId: currentUserId,
              username: username,
              avatarUrl: avatarUrl,
              onLikeChanged: onLikeChanged,
            ),
          );
        },
      ),
    );
  }
}
