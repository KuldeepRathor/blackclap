import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constants/color_constants.dart';
import '../../../models/post_model.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final images = post.imageUrls;

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + username
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accent,
                    backgroundImage: post.profileImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(post.profileImageUrl)
                        : null,
                    child: post.profileImageUrl.isEmpty
                        ? Text(
                            post.username.isNotEmpty
                                ? post.username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: AppColors.onAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username.isNotEmpty ? post.username : post.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      if (post.location.isNotEmpty)
                        Text(
                          post.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral200,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: AppColors.onSurface),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Image carousel
            if (images.isNotEmpty) ...[
              AspectRatio(
                aspectRatio: 1,
                child: PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemBuilder: (context, i) => CachedNetworkImage(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.neutral600,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.neutral600,
                      child: const Icon(Icons.image_not_supported, color: AppColors.neutral500),
                    ),
                  ),
                ),
              ),
              if (images.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentImageIndex == i ? 8 : 6,
                        height: _currentImageIndex == i ? 8 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == i
                              ? AppColors.accent
                              : AppColors.neutral400,
                        ),
                      ),
                    ),
                  ),
                ),
            ],

            // Action row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: AppColors.onSurface),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: AppColors.onSurface),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_outlined, color: AppColors.onSurface),
                    onPressed: () {},
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border, color: AppColors.onSurface),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Likes count
            if (post.likes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${post.likes.length} likes',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ),

            // Caption
            if (post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.onSurface),
                    children: [
                      TextSpan(
                        text: '${post.username.isNotEmpty ? post.username : post.fullName}  ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: post.caption),
                    ],
                  ),
                ),
              ),

            // Comments
            if (post.comments.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  'View all ${post.comments.length} comments',
                  style: const TextStyle(color: AppColors.neutral200),
                ),
              ),
              ...post.comments.take(2).map(
                    (c) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: AppColors.onSurface),
                          children: [
                            TextSpan(
                              text: '${c.username}  ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: c.comment),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],

            // Timestamp
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                _formatDate(post.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.neutral200),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}w ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
