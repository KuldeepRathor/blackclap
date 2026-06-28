# Blackclap — Social Media Mobile App

A full-featured social media app built with Flutter, inspired by Instagram. It pairs
a Flutter client with a custom **FastAPI backend** for REST + realtime WebSocket
chat, and uses **Azure Blob Storage** for direct media uploads.

## 🚀 Implemented Features

### Authentication

- **Register** with email, username, and password (optional display name).
- **Login** with email *or* username + password.
- **JWT session** — access + refresh tokens persisted locally via `SharedPreferences` (`TokenStorage`).
- **Auto session restore** on app launch (`AuthCheckRequested`); routes to home or login accordingly.
- **Resilient profile refresh** — a failed background `getProfile()` keeps the cached user instead of forcing a logout.
- **Logout** clears tokens and tears down the chat socket.

### Feed & Posts

- **Home feed** — paginated (`limit`/`offset`), newest-first, pull-to-refresh.
- **Create posts** — image (multi-image), text-only, and **video posts** (with thumbnail).
- **Tag users** in a post.
- **Like / unlike** (toggle) and **save / unsave** (toggle).
- **Comments** — add, delete, **nested replies**, and cursor-based pagination.
- **Delete** your own posts.
- **Saved posts** and **tagged posts** feeds.

### Profile

- **Your profile** with a posts grid and stats.
- **Other users' profiles** by username.
- **Edit profile** — display name, username, bio, and **avatar upload**.
- **Followers / following** lists with **follow / unfollow**.

### Discover & Search

- **Debounced real-time search** across **users** and **posts** (tabbed results).
- **Browse mode** — real feed posts rendered in a staggered grid.
- **Paginated** search results.

### Chat & Messaging (Realtime)

- **Conversation list** with unread tracking (cursor-paginated).
- **Direct messages** — open-or-create a DM with any user.
- **Realtime delivery** over a native FastAPI **WebSocket**.
- **Optimistic send** using a client message id, with REST as the source of truth.
- **Typing indicators** and **read receipts**.
- **Online status** for participants.
- **Unread badge** on the chat tab in the bottom nav bar.
- **Auto-reconnect** with exponential backoff + jitter, plus a heartbeat ping/pong.
- The socket lifecycle follows the session — it connects on login, disconnects on logout.

### Reels

- **Vertical video feed** (cursor-paginated), full-screen playback.
- **View tracking** and a dedicated **video cache manager** for smooth scrolling.

### Stories

- **Stories** viewer/creator screen *(currently backed by local mock data)*.

### Settings & Theming

- **Light / dark theme** toggle with persistence (`ThemeCubit` + `SharedPreferences`); defaults to dark.
- **Settings screen** (appearance, account, content, and about sections).

### Media Uploads

- **Direct-to-storage uploads** via a presigned / SAS URL flow:
  1. Request a short-lived upload URL from the backend.
  2. `PUT` the file bytes straight to **Azure Blob Storage**.
  3. Persist the resulting blob URL on the post / profile.

## 🛠 Tech Stack

- **Framework:** Flutter (Dart, SDK `>=3.6.0 <4.0.0`)
- **State management:** BLoC / Cubit (`flutter_bloc`, `bloc`, `equatable`)
- **Backend:** Custom FastAPI server — REST + WebSocket (`/api/v1`)
- **Networking:** `http` with a custom `ApiService` + request/response `HttpLogger`
- **Realtime:** `web_socket_channel`
- **Storage / uploads:** Azure Blob Storage (presigned/SAS direct upload)
- **Navigation:** `go_router` + `persistent_bottom_nav_bar`
- **Media:** `image_picker`, `cached_network_image`, `video_player`, `video_thumbnail`, `flutter_cache_manager`, `visibility_detector`
- **UI:** Material 3, `shimmer`, `flutter_staggered_grid_view`
- **Local storage:** `shared_preferences`
- **Misc:** `permission_handler`, `path_provider`, `intl`

> **Note:** `firebase_core` / `firebase_auth` are present as dependencies, but Firebase
> initialization is intentionally **disabled** in `main.dart` — the app runs entirely
> against the custom backend.

## 🧭 App Navigation

The main shell (`MainNavigationWrapper`) is a persistent bottom tab bar with five tabs:

1. **Home** — feed
2. **Search** — discover / search
3. **Chat** — messages (with unread badge)
4. **Reels** — vertical video feed
5. **Profile** — your profile

Additional routes: create post, stories, reels, edit profile, other-user profile,
follow lists, chat thread, new message, and settings.

## 🏗 Project Structure

```text
lib/
├── main.dart                       # App entry, providers, GoRouter, bottom-nav shell
├── config/
│   └── app_url.dart                # Backend host/port + all REST & WS endpoints
├── constants/
│   └── color_constants.dart
├── navigation/
│   └── app_tab_controller.dart     # Exposes the persistent tab controller to descendants
├── blocs/
│   ├── auth/                       # auth_bloc / event / state
│   ├── posts/                      # posts_bloc / event / state
│   ├── chat/                       # chat + conversations blocs
│   ├── search/                     # search_bloc / event / state
│   └── theme/theme_cubit.dart      # light/dark theme + persistence
├── repositories/
│   ├── user_repository.dart
│   ├── post_repository.dart
│   ├── story_repository.dart
│   ├── chat_repository.dart        # owns one REST service + one socket
│   └── mock_data_service.dart      # demo data (stories, some legacy paths)
├── services/
│   ├── api_service.dart            # core HTTP client (auth headers, errors, uploads)
│   ├── post_api_service.dart       # feed / reels / posts / media uploads
│   ├── interaction_api_service.dart# likes, saves, comments
│   ├── search_api_service.dart
│   ├── chat_api_service.dart       # REST chat
│   ├── chat_socket_service.dart    # WebSocket transport (reconnect + heartbeat)
│   ├── token_storage.dart          # JWT access/refresh persistence
│   ├── video_cache_manager.dart
│   ├── http_logger.dart
│   └── firebase_auth_service.dart  # (present, unused by default)
├── models/                         # user, post, comment, conversation, message,
│                                   # participant, story, search_result, chat_socket_event
└── views/
    ├── screens/
    │   ├── auth/                   # login, signup
    │   └── main/                   # feed, discover, create_post, messages, chat,
    │                               # new_message, profile, other_user_profile,
    │                               # edit_profile, follow_list, stories, reels, settings
    └── widgets/                    # feed_post_card, post_card, comments_sheet,
                                    # conversation_tile, message_bubble
```

## 🔧 Setup

### Prerequisites

- Flutter SDK (Dart `>=3.6.0 <4.0.0`)
- A running instance of the Blackclap **FastAPI backend** (REST + WebSocket)
- Android Studio / Xcode / VS Code

### 1. Configure the backend host
Edit [`lib/config/app_url.dart`](lib/config/app_url.dart) to point at your backend:

```dart
static const String _devHost = '192.168.31.139'; // physical device on same Wi-Fi
// static const String _devHost = '10.0.2.2';     // Android emulator
static const String _devPort = '8000';
static const bool _isProduction = false;          // toggle for prod builds
```

Both the REST base (`baseUrl`) and the WebSocket base (`wsBaseUrl`) are derived from
the same host so dev/prod stay in sync.

### 2. Install & run

```bash
flutter pub get
flutter run
```

## 🌐 Backend API

All endpoints are namespaced under `/api/v1`. The chat WebSocket passes the JWT as a
query param (`?token=...`) because WS clients can't set headers.

| Area     | Endpoints (examples)                                                                 |
|----------|--------------------------------------------------------------------------------------|
| Auth     | `POST /auth/register`, `POST /auth/login`                                             |
| Users    | `GET/PATCH /users/me`, `GET /users/{username}`, `GET /users/me/saved-posts`           |
| Follows  | `POST/DELETE /follows/{username}`, `GET /follows/{username}/followers` · `/following`  |
| Posts    | `GET /posts/feed`, `GET /posts/reels`, `GET /posts/me`, `GET /posts/user/{username}`, `POST /posts`, `DELETE /posts/{id}`, `POST /posts/{id}/view` |
| Tagged   | `GET /posts/me/tagged`, `GET /posts/tagged/{username}`                                |
| Interact | `POST /posts/{id}/like`, `POST /posts/{id}/save`, `GET/POST /posts/{id}/comments`, replies, delete |
| Search   | `GET /search?q=&type=&limit=&offset=`                                                 |
| Uploads  | `POST /uploads/url`, `POST /media/presigned-url` (then direct `PUT` to Azure)         |
| Chat     | REST conversation/message endpoints + `WS /ws/chat`                                   |

## 🔐 Authentication Flow

1. **Sign up / Sign in** → backend returns `access_token` + `refresh_token` + user.
2. Tokens are saved via `TokenStorage` (SharedPreferences).
3. On launch, `AuthCheckRequested` validates the stored session and routes accordingly.
4. Authenticated requests attach `Authorization: Bearer <access_token>`.
5. On login the chat WebSocket connects; on logout it disconnects and tokens are cleared.

## 💬 Realtime Chat Architecture

- `ChatRepository` is the single dependency for the chat BLoCs and owns **one REST
  service + one socket** — the only place that knows both transports exist.
- `ChatSocketService` is a standalone WebSocket transport that:
  - parses server frames into typed `ChatEvent`s,
  - auto-reconnects with exponential backoff + jitter (capped),
  - sends a heartbeat `ping` every 25s and swallows `pong` acks,
  - emits typing + read-receipt events.
- Sends are **optimistic** (client message id) with REST as the durable source of truth.

## 🔮 Roadmap / Not Yet Wired to Backend

- **Stories** currently use local mock data (`MockDataService`).
- Some legacy `UserRepository`/`PostRepository` paths (e.g. `getUsers`, `getPost`,
  in-memory like/unlike) still read from mock data.
- Settings sub-pages (Privacy, Notifications, Security, Language, Data Usage) are placeholders.
- Push notifications.

## 📄 License

Licensed under the MIT License — see the `LICENSE` file for details.

---

**Blackclap** — connect with your people. 👏
