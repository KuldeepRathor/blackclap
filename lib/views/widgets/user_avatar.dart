import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constants/color_constants.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackName;
  final double radius;
  final bool showBorder;
  final Color borderColor;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackName,
    this.radius = 20,
    this.showBorder = false,
    this.borderColor = AppColors.accent,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final initials =
        fallbackName.isNotEmpty ? fallbackName[0].toUpperCase() : 'U';

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.accent,
      backgroundImage: hasImage ? CachedNetworkImageProvider(imageUrl!) : null,
      child: !hasImage
          ? Text(
              initials,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnAccent,
              ),
            )
          : null,
    );

    if (showBorder) {
      avatar = Container(
        width: radius * 2 + 4,
        height: radius * 2 + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor ?? AppColors.accent,
            backgroundImage:
                hasImage ? CachedNetworkImageProvider(imageUrl!) : null,
            child: !hasImage
                ? Text(
                    initials,
                    style: TextStyle(
                      fontSize: radius * 0.8,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnAccent,
                    ),
                  )
                : null,
          ),
        ),
      );
    }

    return avatar;
  }
}
