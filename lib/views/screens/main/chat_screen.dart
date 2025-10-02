import 'package:flutter/material.dart';
import '../../../constants/color_constants.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chat',
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
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.accent,
            ),
            SizedBox(height: 16),
            Text(
              'Chat Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This is the chat screen',
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