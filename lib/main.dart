import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'views/screens/auth/login_screen.dart';
import 'views/screens/auth/signup_screen.dart';
import 'views/screens/main/feed_screen.dart';
import 'views/screens/main/discover_screen.dart';
import 'views/screens/main/profile_screen.dart';
import 'views/screens/main/create_post_screen.dart';
import 'views/screens/main/messages_screen.dart';
import 'views/screens/main/stories_screen.dart';
import 'views/screens/main/reels_screen.dart';
import 'views/screens/main/edit_profile_screen.dart';
import 'views/screens/main/other_user_profile_screen.dart';
import 'views/screens/main/follow_list_screen.dart';
import 'views/screens/main/chat_screen.dart';
import 'views/screens/main/new_message_screen.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/posts/posts_bloc.dart';
import 'repositories/user_repository.dart';
import 'repositories/post_repository.dart';
import 'repositories/chat_repository.dart';
import 'models/conversation_model.dart';
import 'constants/color_constants.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Skip Firebase initialization as per request to run only custom backend auth APIs
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BlackClapApp());
}

class BlackClapApp extends StatelessWidget {
  const BlackClapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserRepository>(
          create: (context) => UserRepository(),
        ),
        RepositoryProvider<PostRepository>(
          create: (context) => PostRepository(),
        ),
        RepositoryProvider<ChatRepository>(
          create: (context) => ChatRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(userRepository: context.read<UserRepository>())
                  ..add(AuthCheckRequested()),
          ),
          BlocProvider<PostsBloc>(
            create: (context) => PostsBloc(
              postRepository: context.read<PostRepository>(),
            ),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          // Open the chat WebSocket once authenticated; close it on logout so
          // the unread badge / live delivery follow the session lifecycle.
          listenWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType,
          listener: (context, state) {
            final chatRepo = context.read<ChatRepository>();
            if (state is AuthAuthenticated) {
              chatRepo.connectSocket();
            } else if (state is AuthUnauthenticated) {
              chatRepo.disconnectSocket();
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            // Only recreate the GoRouter when authentication STATUS changes,
            // not on every user-data refresh (avoids navigation reset on getProfile() calls).
            buildWhen: (previous, current) =>
                previous.runtimeType != current.runtimeType,
            builder: (context, state) {
              return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Blackclap',
              theme: ThemeData(
                colorScheme: AppColorScheme.darkScheme,
                useMaterial3: true,
                scaffoldBackgroundColor: AppColors.background,
                appBarTheme: const AppBarTheme(
                  centerTitle: true,
                  elevation: 0,
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.onSurface,
                ),
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  backgroundColor: AppColors.surface,
                  selectedItemColor: AppColors.accent,
                  unselectedItemColor: AppColors.neutral400,
                  type: BottomNavigationBarType.fixed,
                ),
                cardTheme: const CardThemeData(
                  color: AppColors.surface,
                  elevation: 2,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                  ),
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.neutral600),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.neutral600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              routerConfig: _createRouter(state),
            );
          },
          ), // BlocBuilder
        ), // BlocListener
      ), // MultiBlocProvider
    ); // MultiRepositoryProvider
  }

  GoRouter _createRouter(AuthState authState) {
    return GoRouter(
      initialLocation: authState is AuthAuthenticated ? '/home' : '/login',
      redirect: (context, state) {
        // Read current auth state at navigation time, not the stale closure value.
        final currentAuth = BlocProvider.of<AuthBloc>(context, listen: false).state;
        final isAuthenticated = currentAuth is AuthAuthenticated;
        final isLoggingIn =
            state.uri.path == '/login' || state.uri.path == '/signup';

        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }
        if (isAuthenticated && isLoggingIn) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const MainNavigationWrapper(),
        ),
        GoRoute(
          path: '/create-post',
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/stories',
          builder: (context, state) => const StoriesScreen(),
        ),
        GoRoute(
          path: '/reels',
          builder: (context, state) => const ReelsScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/profile/:username',
          builder: (context, state) {
            final username = state.pathParameters['username']!;
            return OtherUserProfileScreen(username: username);
          },
        ),
        GoRoute(
          path: '/follow-list/:username',
          builder: (context, state) {
            final username = state.pathParameters['username']!;
            final tab = int.tryParse(
                    state.uri.queryParameters['tab'] ?? '0') ??
                0;
            return FollowListScreen(username: username, initialTab: tab);
          },
        ),
        GoRoute(
          path: '/chat/:conversationId',
          builder: (context, state) {
            final conversationId = state.pathParameters['conversationId']!;
            final conversation = state.extra as ConversationModel?;
            return ChatScreen(
              conversationId: conversationId,
              conversation: conversation,
            );
          },
        ),
        GoRoute(
          path: '/new-message',
          builder: (context, state) => const NewMessageScreen(),
        ),
      ],
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  List<Widget> _buildScreens() {
    return [
      const FeedScreen(),
      const DiscoverScreen(),
      const MessagesScreen(),
      const ReelsScreen(),
      const ProfileScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        inactiveIcon: const Icon(Icons.home_outlined),
        activeColorPrimary: AppColors.accent,
        inactiveColorPrimary: AppColors.neutral400,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.search),
        inactiveIcon: const Icon(Icons.search_outlined),
        activeColorPrimary: AppColors.accent,
        inactiveColorPrimary: AppColors.neutral400,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.chat_bubble),
        inactiveIcon: const Icon(Icons.chat_bubble_outline),
        activeColorPrimary: AppColors.accent,
        inactiveColorPrimary: AppColors.neutral400,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.play_circle_filled),
        inactiveIcon: const Icon(Icons.play_circle_outline),
        activeColorPrimary: AppColors.accent,
        inactiveColorPrimary: AppColors.neutral400,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        inactiveIcon: const Icon(Icons.person_outline),
        activeColorPrimary: AppColors.accent,
        inactiveColorPrimary: AppColors.neutral400,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      popBehaviorOnSelectedNavBarItemPress: PopBehavior.once,
      backgroundColor: AppColors.surface,
      navBarStyle: NavBarStyle.style3,
    );
  }
}
