import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../utils/theme_colors.dart';
import '../../../models/post_model.dart';
import '../../widgets/post_card.dart';

class PostDetailScreen extends StatelessWidget {
  final PostModel post;
  final void Function(bool isLiked, int likesCount)? onLikeChanged;

  const PostDetailScreen({super.key, required this.post, this.onLikeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final currentUserId =
              authState is AuthAuthenticated ? authState.user.uid : '';
          final currentUsername = authState is AuthAuthenticated
              ? authState.user.username
              : null;
          final currentAvatarUrl = authState is AuthAuthenticated
              ? authState.user.profileImageUrl
              : null;

          return SingleChildScrollView(
            child: PostCard(
              post: post,
              currentUserId: currentUserId,
              currentUsername: currentUsername,
              currentAvatarUrl: currentAvatarUrl,
              onLikeChanged: onLikeChanged,
            ),
          );
        },
      ),
    );
  }
}
