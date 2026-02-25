import 'dart:async';
import 'package:flutter/material.dart';
import '../../../constants/color_constants.dart';
import '../../../repositories/mock_data_service.dart';

class StoryViewerScreen extends StatefulWidget {
  final int initialIndex;

  const StoryViewerScreen({super.key, this.initialIndex = 0});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late PageController _pageController;
  late List<Map<String, dynamic>> _stories;
  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;
  bool _isPaused = false;
  static const int _storyDurationMs = 5000;
  static const int _timerIntervalMs = 50;

  @override
  void initState() {
    super.initState();
    _stories = MockDataService.getStories();
    _currentIndex = widget.initialIndex.clamp(0, _stories.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(
      const Duration(milliseconds: _timerIntervalMs),
      (timer) {
        if (!_isPaused) {
          setState(() {
            _progress += _timerIntervalMs / _storyDurationMs;
            if (_progress >= 1.0) {
              _nextStory();
            }
          });
        }
      },
    );
  }

  void _nextStory() {
    if (_currentIndex < _stories.length - 1) {
      setState(() => _currentIndex++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _startTimer();
    }
  }

  String _formatTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const Scaffold(body: Center(child: Text('No stories')));
    }

    final story = _stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => setState(() => _isPaused = true),
        onLongPressEnd: (_) => setState(() => _isPaused = false),
        onVerticalDragEnd: (d) {
          if (d.primaryVelocity != null && d.primaryVelocity! > 200) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // PageView
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stories.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _startTimer();
              },
              itemBuilder: (context, index) {
                final s = _stories[index];
                return Image.network(
                  s['imageUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.textOnAccent));
                  },
                );
              },
            ),

            // Tap zones
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _prevStory,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _nextStory,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),

            // Progress bars
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: List.generate(_stories.length, (index) {
                      double segmentProgress;
                      if (index < _currentIndex) {
                        segmentProgress = 1.0;
                      } else if (index == _currentIndex) {
                        segmentProgress = _progress;
                      } else {
                        segmentProgress = 0.0;
                      }
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: segmentProgress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // Header: Avatar + username + time + close
            Positioned(
              top: 52,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: story['profileImageUrl'] != null
                            ? NetworkImage(story['profileImageUrl'])
                            : null,
                        backgroundColor: AppColors.accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story['username'] ?? 'unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatTime(story['createdAt']),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Caption at bottom
            if (story['caption'] != null &&
                (story['caption'] as String).isNotEmpty)
              Positioned(
                bottom: 60,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    story['caption'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
