# Blackclap - Social Media Mobile App

A comprehensive social media mobile app built with Flutter, inspired by Instagram but with unique AI-powered features. The app includes user authentication, real-time messaging, post creation, stories, reels, and AI-powered content discovery.

## 🚀 Features

### Core Features
- **User Authentication**: Sign up, login, and profile management with Firebase Auth
- **Main Feed**: Scrolling feed displaying posts from followed users
- **Profile Page**: User profiles with stats, posts grid, and bio
- **Post Creation**: Create and share posts with images and captions
- **Real-time Messaging**: Direct messaging with real-time updates
- **Stories**: Ephemeral content that disappears after 24 hours
- **Reels**: Vertical video feed for short, looping videos

### AI-Powered Features
- **AI Vibe Match**: Find users with similar interests using AI analysis
- **AI Content Suggestions**: Personalized content recommendations based on user activity
- **Smart Search**: Enhanced user and content discovery

## 🛠 Tech Stack

- **Frontend**: Flutter with Dart
- **State Management**: Riverpod
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Navigation**: GoRouter
- **Image Handling**: Image Picker, Cached Network Image
- **UI Components**: Material Design 3

## 📱 Screens

### Authentication
- `LoginScreen`: User login with email/password
- `SignupScreen`: User registration with profile setup

### Main App
- `FeedScreen`: Main scrolling feed with posts
- `DiscoverScreen`: AI-powered discovery and search
- `CreatePostScreen`: Post creation with image upload
- `MessagesScreen`: Chat list and conversations
- `ChatScreen`: Real-time messaging interface
- `ProfileScreen`: User profile with posts and stats
- `StoriesScreen`: Stories creation and viewing
- `ReelsScreen`: Vertical video feed

## 🏗 Project Structure

```
lib/
├── main.dart                 # App entry point and routing
├── providers/
│   └── auth_provider.dart    # Authentication state management
├── services/
│   └── firestore_service.dart # Firebase operations
└── screens/
    ├── auth/
    │   ├── login_screen.dart
    │   └── signup_screen.dart
    └── main/
        ├── feed_screen.dart
        ├── discover_screen.dart
        ├── create_post_screen.dart
        ├── messages_screen.dart
        ├── chat_screen.dart
        ├── profile_screen.dart
        ├── stories_screen.dart
        └── reels_screen.dart
```

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Firebase project setup
- Android Studio / VS Code

### Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Enable Firestore Database
4. Enable Firebase Storage
5. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
6. Place these files in the appropriate platform directories

### Installation
1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## 📦 Dependencies

### Core Dependencies
- `flutter_riverpod`: State management
- `firebase_core`: Firebase initialization
- `firebase_auth`: User authentication
- `cloud_firestore`: Real-time database
- `firebase_storage`: File storage
- `go_router`: Navigation
- `image_picker`: Image selection
- `cached_network_image`: Image caching
- `intl`: Date formatting

### UI Dependencies
- `flutter_staggered_grid_view`: Grid layouts
- `shimmer`: Loading animations
- `video_player`: Video playback

## 🔐 Authentication Flow

1. **Sign Up**: Users create accounts with email, password, username, and bio
2. **Sign In**: Email/password authentication
3. **Profile Creation**: User data stored in Firestore
4. **Session Management**: Automatic login state management

## 💬 Messaging System

- **Real-time Updates**: Messages sync instantly across devices
- **Chat Interface**: Modern chat UI with message bubbles
- **Media Support**: Image and file sharing capabilities
- **User Search**: Find and start conversations with other users

## 🎨 AI Features Implementation

### AI Vibe Match
- Users input interests and bio
- AI analyzes compatibility with other users
- Suggests potential connections based on shared interests

### AI Content Suggestions
- Analyzes user activity (likes, follows, posts)
- Provides personalized content recommendations
- Shows trending topics based on user preferences

## 📊 Database Schema

### Users Collection
```json
{
  "uid": "string",
  "email": "string",
  "username": "string",
  "fullName": "string",
  "bio": "string",
  "profileImageUrl": "string",
  "followers": ["string"],
  "following": ["string"],
  "posts": ["string"],
  "interests": ["string"],
  "isVerified": "boolean",
  "createdAt": "timestamp"
}
```

### Posts Collection
```json
{
  "uid": "string",
  "caption": "string",
  "imageUrls": ["string"],
  "location": "string",
  "likes": ["string"],
  "comments": ["string"],
  "createdAt": "timestamp"
}
```

### Messages Collection
```json
{
  "senderId": "string",
  "receiverId": "string",
  "message": "string",
  "imageUrl": "string",
  "createdAt": "timestamp",
  "isRead": "boolean"
}
```

## 🚀 Getting Started

1. **Clone the repository**
2. **Set up Firebase project**
3. **Install dependencies**: `flutter pub get`
4. **Configure Firebase**: Add configuration files
5. **Run the app**: `flutter run`

## 🔮 Future Enhancements

- **Video Posts**: Support for video content
- **Live Streaming**: Real-time video streaming
- **Advanced AI**: Machine learning for better recommendations
- **Push Notifications**: Real-time notifications
- **Dark Mode**: Theme switching
- **Offline Support**: Offline-first architecture
- **Analytics**: User engagement tracking

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions, please open an issue in the repository or contact the development team.

---

**Your Bird** - Connect with your flock! 🐦
