import 'package:flutter/material.dart';
import '../../../constants/color_constants.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Stories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () {
              // Create story
            },
            color: AppColors.onSurface,
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 80,
              color: AppColors.accent,
            ),
            SizedBox(height: 16),
            Text(
              'Stories Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This is the stories screen',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.neutral200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}