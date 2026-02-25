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
      'profileImageUrl': 'https://picsum.photos/200/200?random=10',
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
      'profileImageUrl': 'https://picsum.photos/200/200?random=11',
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
      'profileImageUrl': 'https://picsum.photos/200/200?random=12',
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
      'profileImageUrl': 'https://picsum.photos/200/200?random=13',
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
      'profileImageUrl': 'https://picsum.photos/200/200?random=14',
      'caption': 'New recipe I tried today! 🍳',
      'imageUrls': ['https://picsum.photos/400/400?random=8'],
      'likes': ['user2', 'user4'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      'location': 'Kitchen',
    },
    {
      'id': '6',
      'uid': 'user6',
      'username': 'emma_white',
      'fullName': 'Emma White',
      'profileImageUrl': 'https://picsum.photos/200/200?random=15',
      'caption': 'City lights never get old ✨🌆',
      'imageUrls': ['https://picsum.photos/400/400?random=30'],
      'likes': ['user1', 'user2', 'user3', 'user4'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
      'location': 'Downtown',
    },
    {
      'id': '7',
      'uid': 'user7',
      'username': 'liam_tech',
      'fullName': 'Liam Foster',
      'profileImageUrl': 'https://picsum.photos/200/200?random=16',
      'caption': 'New personal best at the gym 💪🔥',
      'imageUrls': [
        'https://picsum.photos/400/400?random=31',
        'https://picsum.photos/400/400?random=32',
      ],
      'likes': ['user2', 'user5', 'user8'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
      'location': 'The Gym',
    },
    {
      'id': '8',
      'uid': 'user8',
      'username': 'olivia_art',
      'fullName': 'Olivia Chen',
      'profileImageUrl': 'https://picsum.photos/200/200?random=17',
      'caption': 'Finished my latest painting 🎨🖌️',
      'imageUrls': ['https://picsum.photos/400/400?random=33'],
      'likes': ['user1', 'user4', 'user6'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(hours: 10)),
      'location': 'Art Studio',
    },
    {
      'id': '9',
      'uid': 'user9',
      'username': 'noah_travel',
      'fullName': 'Noah Rivers',
      'profileImageUrl': 'https://picsum.photos/200/200?random=18',
      'caption': 'Road trip to the coast 🚗🌊',
      'imageUrls': [
        'https://picsum.photos/400/400?random=34',
        'https://picsum.photos/400/400?random=35',
        'https://picsum.photos/400/400?random=36',
      ],
      'likes': ['user2', 'user3', 'user7'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      'location': 'Pacific Coast Highway',
    },
    {
      'id': '10',
      'uid': 'user10',
      'username': 'ava_music',
      'fullName': 'Ava Singh',
      'profileImageUrl': 'https://picsum.photos/200/200?random=19',
      'caption': 'Late night studio session 🎵🎹',
      'imageUrls': ['https://picsum.photos/400/400?random=37'],
      'likes': ['user1', 'user5', 'user8', 'user9'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      'location': 'Recording Studio',
    },
    {
      'id': '11',
      'uid': 'user1',
      'username': 'john_doe',
      'fullName': 'John Doe',
      'profileImageUrl': 'https://picsum.photos/200/200?random=10',
      'caption': 'Morning hike ft. misty mountains 🌄',
      'imageUrls': [
        'https://picsum.photos/400/400?random=38',
        'https://picsum.photos/400/400?random=39',
      ],
      'likes': ['user3', 'user6'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      'location': 'Blue Ridge',
    },
    {
      'id': '12',
      'uid': 'user3',
      'username': 'mike_wilson',
      'fullName': 'Mike Wilson',
      'profileImageUrl': 'https://picsum.photos/200/200?random=12',
      'caption': 'New desk setup is 🔥',
      'imageUrls': ['https://picsum.photos/400/400?random=40'],
      'likes': ['user2', 'user4', 'user7'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 4)),
      'location': 'Home Office',
    },
    {
      'id': '13',
      'uid': 'user6',
      'username': 'emma_white',
      'fullName': 'Emma White',
      'profileImageUrl': 'https://picsum.photos/200/200?random=15',
      'caption': 'Sunday brunch goals 🥂🥞',
      'imageUrls': [
        'https://picsum.photos/400/400?random=41',
        'https://picsum.photos/400/400?random=42',
      ],
      'likes': ['user1', 'user5', 'user9', 'user10'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      'location': 'The Brunch Spot',
    },
    {
      'id': '14',
      'uid': 'user8',
      'username': 'olivia_art',
      'fullName': 'Olivia Chen',
      'profileImageUrl': 'https://picsum.photos/200/200?random=17',
      'caption': 'Sketches from today\'s session 📐✏️',
      'imageUrls': [
        'https://picsum.photos/400/400?random=43',
        'https://picsum.photos/400/400?random=44',
        'https://picsum.photos/400/400?random=45',
      ],
      'likes': ['user2', 'user3'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 6)),
      'location': 'Art Studio',
    },
    {
      'id': '15',
      'uid': 'user9',
      'username': 'noah_travel',
      'fullName': 'Noah Rivers',
      'profileImageUrl': 'https://picsum.photos/200/200?random=18',
      'caption': 'Golden hour at the desert 🌅🏜️',
      'imageUrls': ['https://picsum.photos/400/400?random=46'],
      'likes': ['user1', 'user4', 'user6', 'user10'],
      'comments': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 7)),
      'location': 'Mojave Desert',
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
      'posts': ['1', '11'],
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
      'posts': ['3', '12'],
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
    {
      'uid': 'user6',
      'username': 'emma_white',
      'fullName': 'Emma White',
      'email': 'emma@example.com',
      'bio': 'City Explorer 🌆 | Foodie 🥐',
      'profileImageUrl': 'https://picsum.photos/200/200?random=15',
      'followers': ['user1', 'user7', 'user8'],
      'following': ['user1', 'user2'],
      'posts': ['6', '13'],
      'interests': ['cities', 'food', 'photography'],
      'isVerified': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 8)),
    },
    {
      'uid': 'user7',
      'username': 'liam_tech',
      'fullName': 'Liam Foster',
      'email': 'liam@example.com',
      'bio': 'Software Engineer 🛠️ | Fitness Geek 💪',
      'profileImageUrl': 'https://picsum.photos/200/200?random=16',
      'followers': ['user3', 'user6'],
      'following': ['user3', 'user5'],
      'posts': ['7'],
      'interests': ['technology', 'fitness', 'health'],
      'isVerified': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 6)),
    },
    {
      'uid': 'user8',
      'username': 'olivia_art',
      'fullName': 'Olivia Chen',
      'email': 'olivia@example.com',
      'bio': 'Artist & Designer 🎨✨',
      'profileImageUrl': 'https://picsum.photos/200/200?random=17',
      'followers': ['user4', 'user6', 'user9'],
      'following': ['user4', 'user6'],
      'posts': ['8', '14'],
      'interests': ['art', 'design', 'painting'],
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'uid': 'user9',
      'username': 'noah_travel',
      'fullName': 'Noah Rivers',
      'email': 'noah@example.com',
      'bio': 'Digital Nomad 🌍 | Adventure Seeker 🏔️',
      'profileImageUrl': 'https://picsum.photos/200/200?random=18',
      'followers': ['user2', 'user5', 'user8'],
      'following': ['user1', 'user7'],
      'posts': ['9', '15'],
      'interests': ['travel', 'hiking', 'photography'],
      'isVerified': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'uid': 'user10',
      'username': 'ava_music',
      'fullName': 'Ava Singh',
      'email': 'ava@example.com',
      'bio': 'Singer-Songwriter 🎵 | Studio Rat 🎹',
      'profileImageUrl': 'https://picsum.photos/200/200?random=19',
      'followers': ['user3', 'user7', 'user9'],
      'following': ['user2', 'user8'],
      'posts': ['10'],
      'interests': ['music', 'songwriting', 'production'],
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
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
    {
      'id': '5',
      'senderId': 'user1',
      'receiverId': 'user3',
      'message': 'Thanks! That trail was incredible.',
      'createdAt':
          DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      'isRead': true,
    },
    {
      'id': '6',
      'senderId': 'user5',
      'receiverId': 'user1',
      'message': 'Check out my new recipe post!',
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
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
    {
      'id': '4',
      'uid': 'user4',
      'username': 'sarah_jones',
      'profileImageUrl': 'https://picsum.photos/200/200?random=13',
      'imageUrl': 'https://picsum.photos/400/600?random=23',
      'caption': 'Trail views 🏔️',
      'createdAt': DateTime.now().subtract(const Duration(hours: 10)),
    },
    {
      'id': '5',
      'uid': 'user6',
      'username': 'emma_white',
      'profileImageUrl': 'https://picsum.photos/200/200?random=15',
      'imageUrl': 'https://picsum.photos/400/600?random=24',
      'caption': 'City vibes 🌆',
      'createdAt': DateTime.now().subtract(const Duration(hours: 12)),
    },
    {
      'id': '6',
      'uid': 'user8',
      'username': 'olivia_art',
      'profileImageUrl': 'https://picsum.photos/200/200?random=17',
      'imageUrl': 'https://picsum.photos/400/600?random=25',
      'caption': 'Work in progress 🎨',
      'createdAt': DateTime.now().subtract(const Duration(hours: 14)),
    },
  ];

  static final List<Map<String, dynamic>> _savedPosts = [];

  static final List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': 'n1',
      'type': 'like',
      'uid': 'user2',
      'username': 'jane_smith',
      'profileImageUrl': 'https://picsum.photos/200/200?random=11',
      'message': 'liked your photo.',
      'postId': '1',
      'postImageUrl': 'https://picsum.photos/400/400?random=1',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 5)),
    },
    {
      'id': 'n2',
      'type': 'comment',
      'uid': 'user3',
      'username': 'mike_wilson',
      'profileImageUrl': 'https://picsum.photos/200/200?random=12',
      'message': 'commented: "Absolutely stunning shot! 🔥"',
      'postId': '1',
      'postImageUrl': 'https://picsum.photos/400/400?random=1',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 12)),
    },
    {
      'id': 'n3',
      'type': 'follow',
      'uid': 'user6',
      'username': 'emma_white',
      'profileImageUrl': 'https://picsum.photos/200/200?random=15',
      'message': 'started following you.',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 40)),
    },
    {
      'id': 'n4',
      'type': 'like',
      'uid': 'user4',
      'username': 'sarah_jones',
      'profileImageUrl': 'https://picsum.photos/200/200?random=13',
      'message': 'liked your photo.',
      'postId': '11',
      'postImageUrl': 'https://picsum.photos/400/400?random=38',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': 'n5',
      'type': 'mention',
      'uid': 'user5',
      'username': 'alex_brown',
      'profileImageUrl': 'https://picsum.photos/200/200?random=14',
      'message': 'mentioned you in a comment.',
      'postId': '5',
      'postImageUrl': 'https://picsum.photos/400/400?random=8',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'id': 'n6',
      'type': 'reel_like',
      'uid': 'user7',
      'username': 'liam_tech',
      'profileImageUrl': 'https://picsum.photos/200/200?random=16',
      'message': 'liked your reel.',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(hours: 8)),
    },
    {
      'id': 'n7',
      'type': 'follow',
      'uid': 'user8',
      'username': 'olivia_art',
      'profileImageUrl': 'https://picsum.photos/200/200?random=17',
      'message': 'started following you.',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(hours: 10)),
    },
    {
      'id': 'n8',
      'type': 'comment',
      'uid': 'user9',
      'username': 'noah_travel',
      'profileImageUrl': 'https://picsum.photos/200/200?random=18',
      'message': 'commented: "This place looks magical! 🌅"',
      'postId': '11',
      'postImageUrl': 'https://picsum.photos/400/400?random=38',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': 'n9',
      'type': 'like',
      'uid': 'user10',
      'username': 'ava_music',
      'profileImageUrl': 'https://picsum.photos/200/200?random=19',
      'message': 'liked your photo.',
      'postId': '1',
      'postImageUrl': 'https://picsum.photos/400/400?random=2',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'id': 'n10',
      'type': 'follow',
      'uid': 'user2',
      'username': 'jane_smith',
      'profileImageUrl': 'https://picsum.photos/200/200?random=11',
      'message': 'and 3 others started following you.',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 4)),
    },
    {
      'id': 'n11',
      'type': 'mention',
      'uid': 'user3',
      'username': 'mike_wilson',
      'profileImageUrl': 'https://picsum.photos/200/200?random=12',
      'message': 'mentioned you in their story.',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'id': 'n12',
      'type': 'reel_like',
      'uid': 'user4',
      'username': 'sarah_jones',
      'profileImageUrl': 'https://picsum.photos/200/200?random=13',
      'message': 'liked your reel.',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 6)),
    },
    {
      'id': 'n13',
      'type': 'comment',
      'uid': 'user6',
      'username': 'emma_white',
      'profileImageUrl': 'https://picsum.photos/200/200?random=15',
      'message': 'commented: "Goal! 🎯🔥"',
      'postId': '1',
      'postImageUrl': 'https://picsum.photos/400/400?random=1',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 7)),
    },
    {
      'id': 'n14',
      'type': 'like',
      'uid': 'user5',
      'username': 'alex_brown',
      'profileImageUrl': 'https://picsum.photos/200/200?random=14',
      'message': 'liked your photo.',
      'postId': '11',
      'postImageUrl': 'https://picsum.photos/400/400?random=38',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 8)),
    },
    {
      'id': 'n15',
      'type': 'follow',
      'uid': 'user7',
      'username': 'liam_tech',
      'profileImageUrl': 'https://picsum.photos/200/200?random=16',
      'message': 'started following you.',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 10)),
    },
  ];

  // ── Reels ────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getReels() {
    return List.from(_mockReels);
  }

  static List<Map<String, dynamic>> getUserReels(String uid) {
    return _mockReels.where((reel) => reel['uid'] == uid).toList();
  }

  static Future<void> likeReel(String reelId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockReels.indexWhere((r) => r['id'] == reelId);
    if (index != -1) {
      final likes = List<String>.from(_mockReels[index]['likes'] ?? []);
      if (!likes.contains(userId)) {
        likes.add(userId);
        _mockReels[index]['likes'] = likes;
      }
    }
  }

  static Future<void> unlikeReel(String reelId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockReels.indexWhere((r) => r['id'] == reelId);
    if (index != -1) {
      final likes = List<String>.from(_mockReels[index]['likes'] ?? []);
      likes.remove(userId);
      _mockReels[index]['likes'] = likes;
    }
  }

  // ── Posts ────────────────────────────────────────────────────────────────

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

  // Fixed: mutate _mockPosts directly instead of via getPost()
  static Future<void> likePost(String postId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockPosts.indexWhere((p) => p['id'] == postId);
    if (index != -1) {
      final likes = List<String>.from(_mockPosts[index]['likes'] ?? []);
      if (!likes.contains(userId)) {
        likes.add(userId);
        _mockPosts[index]['likes'] = likes;
      }
    }
  }

  static Future<void> unlikePost(String postId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockPosts.indexWhere((p) => p['id'] == postId);
    if (index != -1) {
      final likes = List<String>.from(_mockPosts[index]['likes'] ?? []);
      likes.remove(userId);
      _mockPosts[index]['likes'] = likes;
    }
  }

  static Future<void> deletePost(String postId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockPosts.removeWhere((p) => p['id'] == postId);
    // Remove from user's posts list
    for (final user in _mockUsers) {
      final posts = List<String>.from(user['posts'] ?? []);
      posts.remove(postId);
      user['posts'] = posts;
    }
  }

  static Future<void> updatePost(
    String postId, {
    String? caption,
    String? location,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockPosts.indexWhere((p) => p['id'] == postId);
    if (index != -1) {
      if (caption != null) _mockPosts[index]['caption'] = caption;
      if (location != null) _mockPosts[index]['location'] = location;
    }
  }

  static List<Map<String, dynamic>> getComments(String postId) {
    final post = getPost(postId);
    if (post == null) return [];
    return List<Map<String, dynamic>>.from(post['comments'] ?? []);
  }

  static Future<void> addComment({
    required String postId,
    required String uid,
    required String username,
    required String profileImageUrl,
    required String comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockPosts.indexWhere((p) => p['id'] == postId);
    if (index != -1) {
      final comments =
          List<Map<String, dynamic>>.from(_mockPosts[index]['comments'] ?? []);
      comments.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'uid': uid,
        'username': username,
        'profileImageUrl': profileImageUrl,
        'comment': comment,
        'likes': [],
        'replies': [],
        'createdAt': DateTime.now(),
      });
      _mockPosts[index]['comments'] = comments;
    }
  }

  // ── Users ────────────────────────────────────────────────────────────────

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

  static Future<void> updateUser(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockUsers.indexWhere((u) => u['uid'] == uid);
    if (index != -1) {
      updates.forEach((key, value) {
        _mockUsers[index][key] = value;
      });
    }
  }

  static Future<void> followUser(
    String currentUserId,
    String targetUserId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final currentUserIdx = _mockUsers.indexWhere(
      (u) => u['uid'] == currentUserId,
    );
    final targetUserIdx = _mockUsers.indexWhere(
      (u) => u['uid'] == targetUserId,
    );

    if (currentUserIdx != -1 && targetUserIdx != -1) {
      final currentFollowing = List<String>.from(
        _mockUsers[currentUserIdx]['following'] ?? [],
      );
      final targetFollowers = List<String>.from(
        _mockUsers[targetUserIdx]['followers'] ?? [],
      );

      if (!currentFollowing.contains(targetUserId)) {
        currentFollowing.add(targetUserId);
        _mockUsers[currentUserIdx]['following'] = currentFollowing;
      }

      if (!targetFollowers.contains(currentUserId)) {
        targetFollowers.add(currentUserId);
        _mockUsers[targetUserIdx]['followers'] = targetFollowers;
      }
    }
  }

  static Future<void> unfollowUser(
    String currentUserId,
    String targetUserId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final currentUserIdx = _mockUsers.indexWhere(
      (u) => u['uid'] == currentUserId,
    );
    final targetUserIdx = _mockUsers.indexWhere(
      (u) => u['uid'] == targetUserId,
    );

    if (currentUserIdx != -1 && targetUserIdx != -1) {
      final currentFollowing = List<String>.from(
        _mockUsers[currentUserIdx]['following'] ?? [],
      );
      final targetFollowers = List<String>.from(
        _mockUsers[targetUserIdx]['followers'] ?? [],
      );

      currentFollowing.remove(targetUserId);
      targetFollowers.remove(currentUserId);

      _mockUsers[currentUserIdx]['following'] = currentFollowing;
      _mockUsers[targetUserIdx]['followers'] = targetFollowers;
    }
  }

  // ── Messages ─────────────────────────────────────────────────────────────

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

      // Only process messages involving this user
      if (senderId != userId && receiverId != userId) continue;

      final partnerId = receiverId == userId ? senderId : receiverId;

      if (!conversations.containsKey(partnerId) ||
          (message['createdAt'] as DateTime).isAfter(
            conversations[partnerId]!['createdAt'] as DateTime,
          )) {
        conversations[partnerId] = message;
      }
    }

    final result = conversations.entries.map((entry) {
      final partnerId = entry.key;
      final lastMessage = entry.value;
      final partnerUser = getUser(partnerId);
      return {
        ...lastMessage,
        'partnerId': partnerId,
        'partnerName': partnerUser?['fullName'] ?? 'Unknown',
        'partnerUsername': partnerUser?['username'] ?? 'unknown',
        'partnerImageUrl': partnerUser?['profileImageUrl'] ?? '',
      };
    }).toList();

    result.sort(
      (a, b) => (b['createdAt'] as DateTime).compareTo(
        a['createdAt'] as DateTime,
      ),
    );

    return result;
  }

  static Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'createdAt': DateTime.now(),
      'isRead': false,
    };
    _mockMessages.add(newMessage);
  }

  // ── Stories ───────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getStories() {
    return List.from(_mockStories);
  }

  static Future<void> createStory({
    required String uid,
    required String imageUrl,
    String? caption,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = getUser(uid);
    if (user != null) {
      final newStory = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
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

  // ── Saved Posts ───────────────────────────────────────────────────────────

  static List<String> getSavedPosts(String userId) {
    return _savedPosts
        .where((s) => s['userId'] == userId)
        .map((s) => s['postId'] as String)
        .toList();
  }

  static Future<void> savePost(String postId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final exists = _savedPosts.any(
      (s) => s['postId'] == postId && s['userId'] == userId,
    );
    if (!exists) {
      _savedPosts.add({'postId': postId, 'userId': userId});
    }
  }

  static Future<void> unsavePost(String postId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _savedPosts.removeWhere(
      (s) => s['postId'] == postId && s['userId'] == userId,
    );
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getMockNotifications() {
    return List.from(_mockNotifications);
  }

  static void markAllNotificationsRead() {
    for (final n in _mockNotifications) {
      n['isRead'] = true;
    }
  }

  // ── Post creation ─────────────────────────────────────────────────────────

  static Future<void> createPost({
    required String uid,
    required String caption,
    required List<String> imageUrls,
    String location = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = getUser(uid);
    if (user != null) {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final newPost = {
        'id': newId,
        'uid': uid,
        'username': user['username'],
        'fullName': user['fullName'],
        'profileImageUrl': user['profileImageUrl'],
        'caption': caption,
        'imageUrls': imageUrls,
        'likes': [],
        'comments': [],
        'createdAt': DateTime.now(),
        'location': location,
      };
      _mockPosts.insert(0, newPost);

      final userPosts = List<String>.from(user['posts'] ?? []);
      userPosts.insert(0, newId);
      final userIdx = _mockUsers.indexWhere((u) => u['uid'] == uid);
      if (userIdx != -1) _mockUsers[userIdx]['posts'] = userPosts;
    }
  }
}
