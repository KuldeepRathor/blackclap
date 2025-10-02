import '../models/story_model.dart';
import 'mock_data_service.dart';

abstract class StoryRepositoryInterface {
  Future<List<StoryModel>> getStories();
  Future<void> createStory({
    required String uid,
    required String imageUrl,
    String? caption,
  });
}

class StoryRepository implements StoryRepositoryInterface {
  @override
  Future<List<StoryModel>> getStories() async {
    final storyData = MockDataService.getStories();
    return storyData.map((story) => StoryModel.fromMap(story)).toList();
  }

  @override
  Future<void> createStory({
    required String uid,
    required String imageUrl,
    String? caption,
  }) async {
    await MockDataService.createStory(
      uid: uid,
      imageUrl: imageUrl,
      caption: caption,
    );
  }
}