class MockDataService {
  static final List<Map<String, dynamic>> _mockReels = [
    {
      'id': 'reel1',
      'uid': 'user1',
      'username': 'john_doe',
      'fullName': 'John Doe',
      'profileImageUrl': 'https://picsum.photos/200/200?random=10',
      'videoUrl':
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      'thumbnailUrl': 'https://picsum.photos/400/700?random=101',
      'caption': 'Beautiful butterfly in slow motion! 🦋',
      'likes': ['user2', 'user3', 'user4'],
      'comments': [],
      'shares': 12,
      'views': 1523,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      'location': 'Nature Park',
      'musicName': 'Nature Sounds - Original Audio',
      'isVerified': true,
    },
    {
      'id': 'reel2',
      'uid': 'user2',
      'username': 'jane_smith',
      'fullName': 'Jane Smith',
      'profileImageUrl': 'https://picsum.photos/200/200?random=11',
      'videoUrl':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'thumbnailUrl': 'https://picsum.photos/400/700?random=102',
      'caption': 'Big Buck Bunny animation test! 🐰',
      'likes': ['user1', 'user3', 'user5'],
      'comments': [],
      'shares': 23,
      'views': 3421,
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
      'location': 'Animation Studio',
      'musicName': 'Funny Moments - Trending Audio',
      'isVerified': false,
    },
    {
      'id': 'reel3',
      'uid': 'user3',
      'username': 'mike_wilson',
      'fullName': 'Mike Wilson',
      'profileImageUrl': 'https://picsum.photos/200/200?random=12',
      'videoUrl':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'thumbnailUrl': 'https://picsum.photos/400/700?random=103',
      'caption': 'Amazing tech demo! 🚀',
      'likes': ['user1', 'user2', 'user4', 'user5'],
      'comments': [],
      'shares': 45,
      'views': 5678,
      'createdAt': DateTime.now().subtract(const Duration(hours: 8)),
      'location': 'Tech Hub',
      'musicName': 'Electronic Beats - Popular Sound',
      'isVerified': false,
    },
    {
      'id': 'reel4',
      'uid': 'user4',
      'username': 'sarah_jones',
      'fullName': 'Sarah Jones',
      'profileImageUrl': 'https://picsum.photos/200/200?random=13',
      'videoUrl':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'thumbnailUrl': 'https://picsum.photos/400/700?random=104',
      'caption': 'Surreal animation art! 🎨',
      'likes': ['user1', 'user2', 'user3'],
      'comments': [],
      'shares': 67,
      'views': 8901,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'location': 'Art Gallery',
      'musicName': 'Ambient Dreams - Original Audio',
      'isVerified': true,
    },
    {
      'id': 'reel5',
      'uid': 'user5',
      'username': 'alex_brown',
      'fullName': 'Alex Brown',
      'profileImageUrl': 'https://picsum.photos/200/200?random=14',
      'videoUrl':
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'thumbnailUrl': 'https://picsum.photos/400/700?random=105',
      'caption': 'Bee collecting pollen! 🐝🌻',
      'likes': ['user2', 'user4'],
      'comments': [],
      'shares': 34,
      'views': 4567,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      'location': 'Garden',
      'musicName': 'Summer Vibes - Trending Sound',
      'isVerified': false,
    },
  ];

  static final List<Map<String, dynamic>> _mockPosts = [
    {
      'id': '1',
      'uid': 'user1',
      'username': 'john_doe',
      'fullName': 'John Doe',
      'profileImageUrl': '',
      'caption': 'Beautiful sunset today! 🌅',
      'imageUrls': [
        'https://picsum.photos/400/400?random=1',
        'https://picsum.photos/400/400?random=2',
      ],
      'likes': ['user2', 'user3'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      'location': 'Beach',
    },
    {
      'id': '2',
      'uid': 'user2',
      'username': 'jane_smith',
      'fullName': 'Jane Smith',
      'profileImageUrl': '',
      'caption': 'Working on my new Flutter project! 💻',
      'imageUrls': ['https://picsum.photos/400/400?random=3'],
      'likes': ['user1', 'user4'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
      'location': 'Home',
    },
    {
      'id': '3',
      'uid': 'user3',
      'username': 'mike_wilson',
      'fullName': 'Mike Wilson',
      'profileImageUrl': '',
      'caption': 'Coffee and code ☕️',
      'imageUrls': ['https://picsum.photos/400/400?random=4'],
      'likes': ['user1', 'user2', 'user5'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(hours: 8)),
      'location': 'Coffee Shop',
    },
    {
      'id': '4',
      'uid': 'user4',
      'username': 'sarah_jones',
      'fullName': 'Sarah Jones',
      'profileImageUrl': '',
      'caption': 'Amazing hike today! 🥾',
      'imageUrls': [
        'https://picsum.photos/400/400?random=5',
        'https://picsum.photos/400/400?random=6',
        'https://picsum.photos/400/400?random=7',
      ],
      'likes': ['user1', 'user3'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'location': 'Mountain Trail',
    },
    {
      'id': '5',
      'uid': 'user5',
      'username': 'alex_brown',
      'fullName': 'Alex Brown',
      'profileImageUrl': '',
      'caption': 'New recipe I tried today! 🍳',
      'imageUrls': ['https://picsum.photos/400/400?random=8'],
      'likes': ['user2', 'user4'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      'location': 'Kitchen',
    },
  ];

  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'uid': 'user1',
      'username': 'john_doe',
      'fullName': 'John Doe',
      'email': 'john@example.com',
      'bio': 'Photographer & Traveler 📸✈️',
      'profileImageUrl': 'https://picsum.photos/200/200?random=10',
      'followers': ['user2', 'user3', 'user4'],
      'following': ['user2', 'user3'],
      'posts': ['1'],
      'interests': ['photography', 'travel', 'nature'],
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 30)),
    },
    {
      'uid': 'user2',
      'username': 'jane_smith',
      'fullName': 'Jane Smith',
      'email': 'jane@example.com',
      'bio': 'Flutter Developer 💻 | Coffee Lover ☕',
      'profileImageUrl': 'https://picsum.photos/200/200?random=11',
      'followers': ['user1', 'user3', 'user5'],
      'following': ['user1', 'user3'],
      'posts': ['2'],
      'interests': ['flutter', 'programming', 'coffee'],
      'isVerified': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 25)),
    },
    {
      'uid': 'user3',
      'username': 'mike_wilson',
      'fullName': 'Mike Wilson',
      'email': 'mike@example.com',
      'bio': 'Tech Enthusiast | Coffee Addict ☕',
      'profileImageUrl': 'https://picsum.photos/200/200?random=12',
      'followers': ['user1', 'user2', 'user4'],
      'following': ['user1', 'user2'],
      'posts': ['3'],
      'interests': ['technology', 'coffee', 'coding'],
      'isVerified': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 20)),
    },
    {
      'uid': 'user4',
      'username': 'sarah_jones',
      'fullName': 'Sarah Jones',
      'email': 'sarah@example.com',
      'bio': 'Outdoor Adventurer 🥾 | Nature Lover 🌲',
      'profileImageUrl': 'https://picsum.photos/200/200?random=13',
      'followers': ['user1', 'user3', 'user5'],
      'following': ['user1', 'user3'],
      'posts': ['4'],
      'interests': ['hiking', 'nature', 'photography'],
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 15)),
    },
    {
      'uid': 'user5',
      'username': 'alex_brown',
      'fullName': 'Alex Brown',
      'email': 'alex@example.com',
      'bio': 'Chef | Food Blogger 🍳📝',
      'profileImageUrl': 'https://picsum.photos/200/200?random=14',
      'followers': ['user2', 'user4'],
      'following': ['user2', 'user4'],
      'posts': ['5'],
      'interests': ['cooking', 'food', 'recipes'],
      'isVerified': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 10)),
    },
  ];

  static final List<Map<String, dynamic>> _mockMessages = [
    {
      'id': '1',
      'senderId': 'user2',
      'receiverId': 'user1',
      'message': 'Hey! How are you doing?',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
      'isRead': true,
    },
    {
      'id': '2',
      'senderId': 'user1',
      'receiverId': 'user2',
      'message': 'I\'m doing great! Just finished a new photo shoot.',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 25)),
      'isRead': true,
    },
    {
      'id': '3',
      'senderId': 'user3',
      'receiverId': 'user1',
      'message': 'Love your latest post! 📸',
      'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
      'isRead': false,
    },
    {
      'id': '4',
      'senderId': 'user4',
      'receiverId': 'user1',
      'message': 'Want to go hiking this weekend?',
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': false,
    },
  ];

  static final List<Map<String, dynamic>> _mockStories = [
    {
      'id': '1',
      'uid': 'user1',
      'username': 'john_doe',
      'profileImageUrl': 'https://picsum.photos/200/200?random=10',
      'imageUrl': 'https://picsum.photos/400/600?random=20',
      'caption': 'Morning coffee ☕',
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
    },
    {
      'id': '2',
      'uid': 'user2',
      'username': 'jane_smith',
      'profileImageUrl': 'https://picsum.photos/200/200?random=11',
      'imageUrl': 'https://picsum.photos/400/600?random=21',
      'caption': 'Coding session 💻',
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'id': '3',
      'uid': 'user3',
      'username': 'mike_wilson',
      'profileImageUrl': 'https://picsum.photos/200/200?random=12',
      'imageUrl': 'https://picsum.photos/400/600?random=22',
      'caption': 'Coffee break ☕',
      'createdAt': DateTime.now().subtract(const Duration(hours: 8)),
    },
  ];

  static List<Map<String, dynamic>> getReels() {
    return List.from(_mockReels);
  }

  static List<Map<String, dynamic>> getUserReels(String uid) {
    return _mockReels.where((reel) => reel['uid'] == uid).toList();
  }

  static Future<void> likeReel(String reelId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final reel = _mockReels.firstWhere((r) => r['id'] == reelId);
    final likes = List<String>.from(reel['likes'] ?? []);
    if (!likes.contains(userId)) {
      likes.add(userId);
      reel['likes'] = likes;
    }
  }

  static Future<void> unlikeReel(String reelId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final reel = _mockReels.firstWhere((r) => r['id'] == reelId);
    final likes = List<String>.from(reel['likes'] ?? []);
    likes.remove(userId);
    reel['likes'] = likes;
  }

  // Posts
  static List<Map<String, dynamic>> getPosts() {
    return List.from(_mockPosts);
  }

  static List<Map<String, dynamic>> getUserPosts(String uid) {
    return _mockPosts.where((post) => post['uid'] == uid).toList();
  }

  static Map<String, dynamic>? getPost(String postId) {
    try {
      return _mockPosts.firstWhere((post) => post['id'] == postId);
    } catch (e) {
      return null;
    }
  }

  // Users
  static List<Map<String, dynamic>> getUsers() {
    return List.from(_mockUsers);
  }

  static Map<String, dynamic>? getUser(String uid) {
    try {
      return _mockUsers.firstWhere((user) => user['uid'] == uid);
    } catch (e) {
      return null;
    }
  }

  static List<Map<String, dynamic>> searchUsers(String query) {
    return _mockUsers.where((user) {
      final username = user['username']?.toString().toLowerCase() ?? '';
      final fullName = user['fullName']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      return username.contains(searchQuery) || fullName.contains(searchQuery);
    }).toList();
  }

  // Messages
  static List<Map<String, dynamic>> getMessages(
    String currentUserId,
    String otherUserId,
  ) {
    return _mockMessages.where((message) {
      return (message['senderId'] == currentUserId &&
              message['receiverId'] == otherUserId) ||
          (message['senderId'] == otherUserId &&
              message['receiverId'] == currentUserId);
    }).toList();
  }

  static List<Map<String, dynamic>> getConversations(String userId) {
    final conversations = <String, Map<String, dynamic>>{};

    for (final message in _mockMessages) {
      final senderId = message['senderId'] as String;
      final receiverId = message['receiverId'] as String;
      final partnerId = receiverId == userId ? senderId : receiverId;

      if (partnerId != userId) {
        if (!conversations.containsKey(partnerId) ||
            (message['createdAt'] as DateTime).isAfter(
              conversations[partnerId]!['createdAt'] as DateTime,
            )) {
          conversations[partnerId] = message;
        }
      }
    }

    return conversations.values.toList();
  }

  // Stories
  static List<Map<String, dynamic>> getStories() {
    return List.from(_mockStories);
  }

  // Mock actions
  static Future<void> likePost(String postId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final post = getPost(postId);
    if (post != null) {
      final likes = List<String>.from(post['likes'] ?? []);
      if (!likes.contains(userId)) {
        likes.add(userId);
        post['likes'] = likes;
      }
    }
  }

  static Future<void> unlikePost(String postId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final post = getPost(postId);
    if (post != null) {
      final likes = List<String>.from(post['likes'] ?? []);
      likes.remove(userId);
      post['likes'] = likes;
    }
  }

  static Future<void> followUser(
    String currentUserId,
    String targetUserId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final currentUser = getUser(currentUserId);
    final targetUser = getUser(targetUserId);

    if (currentUser != null && targetUser != null) {
      final currentFollowing = List<String>.from(
        currentUser['following'] ?? [],
      );
      final targetFollowers = List<String>.from(targetUser['followers'] ?? []);

      if (!currentFollowing.contains(targetUserId)) {
        currentFollowing.add(targetUserId);
        currentUser['following'] = currentFollowing;
      }

      if (!targetFollowers.contains(currentUserId)) {
        targetFollowers.add(currentUserId);
        targetUser['followers'] = targetFollowers;
      }
    }
  }

  static Future<void> unfollowUser(
    String currentUserId,
    String targetUserId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final currentUser = getUser(currentUserId);
    final targetUser = getUser(targetUserId);

    if (currentUser != null && targetUser != null) {
      final currentFollowing = List<String>.from(
        currentUser['following'] ?? [],
      );
      final targetFollowers = List<String>.from(targetUser['followers'] ?? []);

      currentFollowing.remove(targetUserId);
      targetFollowers.remove(currentUserId);

      currentUser['following'] = currentFollowing;
      targetUser['followers'] = targetFollowers;
    }
  }

  static Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newMessage = {
      'id': '${_mockMessages.length + 1}',
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'createdAt': DateTime.now(),
      'isRead': false,
    };
    _mockMessages.add(newMessage);
  }

  static Future<void> createPost({
    required String uid,
    required String caption,
    required List<String> imageUrls,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final user = getUser(uid);
    if (user != null) {
      final newPost = {
        'id': '${_mockPosts.length + 1}',
        'uid': uid,
        'username': user['username'],
        'fullName': user['fullName'],
        'profileImageUrl': user['profileImageUrl'],
        'caption': caption,
        'imageUrls': imageUrls,
        'likes': [],
        'comments': [],
        'createdAt': DateTime.now(),
        'location': '',
      };
      _mockPosts.insert(0, newPost);

      final userPosts = List<String>.from(user['posts'] ?? []);
      userPosts.add(newPost['id'] as String);
      user['posts'] = userPosts;
    }
  }

  static Future<void> createStory({
    required String uid,
    required String imageUrl,
    String? caption,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final user = getUser(uid);
    if (user != null) {
      final newStory = {
        'id': '${_mockStories.length + 1}',
        'uid': uid,
        'username': user['username'],
        'profileImageUrl': user['profileImageUrl'],
        'imageUrl': imageUrl,
        'caption': caption ?? '',
        'createdAt': DateTime.now(),
      };
      _mockStories.insert(0, newStory);
    }
  }
}
