import 'package:flutter/material.dart';
import '../../../constants/color_constants.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 80,
              color: AppColors.accent,
            ),
            SizedBox(height: 16),
            Text(
              'Messages Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This is the messages screen',
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