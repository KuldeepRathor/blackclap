import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constants/color_constants.dart';

class GradientStoryRing extends StatelessWidget {
  final String? imageUrl;
  final String fallbackName;
  final double radius;
  final bool isViewed;
  final VoidCallback? onTap;

  const GradientStoryRing({
    super.key,
    this.imageUrl,
    required this.fallbackName,
    this.radius = 28,
    this.isViewed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final initials =
        fallbackName.isNotEmpty ? fallbackName[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2 + 6,
        height: radius * 2 + 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isViewed ? null : AppColors.storyRingGradient,
          color: isViewed ? AppColors.neutral300 : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.5),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: radius - 2,
              backgroundColor: AppColors.accentSurface,
              backgroundImage:
                  hasImage ? CachedNetworkImageProvider(imageUrl!) : null,
              child: !hasImage
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: radius * 0.65,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
