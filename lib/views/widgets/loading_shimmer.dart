import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../constants/color_constants.dart';

class PostCardShimmer extends StatelessWidget {
  const PostCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral200,
      highlightColor: AppColors.neutral100,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ListTile(
              leading:
                  const CircleAvatar(backgroundColor: AppColors.neutral200),
              title: Container(
                height: 12,
                width: 120,
                color: AppColors.neutral200,
              ),
              subtitle: Container(
                height: 10,
                width: 80,
                margin: const EdgeInsets.only(top: 4),
                color: AppColors.neutral200,
              ),
            ),
            // Image placeholder
            Container(
              height: 280,
              width: double.infinity,
              color: AppColors.neutral200,
            ),
            const SizedBox(height: 8),
            // Actions row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(height: 24, width: 24, color: AppColors.neutral200),
                  const SizedBox(width: 16),
                  Container(height: 24, width: 24, color: AppColors.neutral200),
                  const SizedBox(width: 16),
                  Container(height: 24, width: 24, color: AppColors.neutral200),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Caption
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(height: 12, color: AppColors.neutral200),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                  height: 12, width: 200, color: AppColors.neutral200),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class ConversationTileShimmer extends StatelessWidget {
  const ConversationTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral200,
      highlightColor: AppColors.neutral100,
      child: ListTile(
        leading: const CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.neutral200,
        ),
        title: Container(height: 12, color: AppColors.neutral200),
        subtitle: Container(
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          color: AppColors.neutral200,
        ),
        trailing: Container(height: 10, width: 40, color: AppColors.neutral200),
      ),
    );
  }
}

class GridShimmer extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;

  const GridShimmer({super.key, this.crossAxisCount = 2, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral200,
      highlightColor: AppColors.neutral100,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: AppColors.neutral200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
