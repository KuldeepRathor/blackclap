import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'views/screens/auth/login_screen.dart';
import 'views/screens/auth/signup_screen.dart';
import 'views/screens/auth/forgot_password_email_screen.dart';
import 'views/screens/auth/verify_reset_code_screen.dart';
import 'views/screens/auth/reset_password_screen.dart';
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
import 'views/screens/main/settings_screen.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/posts/posts_bloc.dart';
import 'blocs/chat/conversations_bloc.dart';
import 'blocs/theme/theme_cubit.dart';
import 'navigation/app_tab_controller.dart';
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
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(),
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
              final router = _createRouter(state);
              return BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  return MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    title: 'Blackclap',
                    theme: AppThemeData.lightTheme,
                    darkTheme: AppThemeData.darkTheme,
                    themeMode: themeMode,
                    themeAnimationDuration: const Duration(milliseconds: 350),
                    themeAnimationCurve: Curves.easeInOut,
                    routerConfig: router,
                  );
                },
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
        // Public (unauthenticated) routes — login/signup and the password-reset flow.
        const publicPaths = {
          '/login',
          '/signup',
          '/forgot-password',
          '/verify-reset-code',
          '/reset-password',
        };
        final isLoggingIn = publicPaths.contains(state.uri.path);

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
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordEmailScreen(),
        ),
        GoRoute(
          path: '/verify-reset-code',
          builder: (context, state) {
            final email = state.extra as String? ?? '';
            return VerifyResetCodeScreen(email: email);
          },
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final args = (state.extra as Map?) ?? const {};
            return ResetPasswordScreen(
              email: args['email'] as String? ?? '',
              code: args['code'] as String? ?? '',
            );
          },
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
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  List<PersistentBottomNavBarItem> _buildNavItems(
      int unread, Color accent, Color inactive) {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        inactiveIcon: const Icon(Icons.home_outlined),
        activeColorPrimary: accent,
        inactiveColorPrimary: inactive,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.search),
        inactiveIcon: const Icon(Icons.search_outlined),
        activeColorPrimary: accent,
        inactiveColorPrimary: inactive,
      ),
      PersistentBottomNavBarItem(
        icon: _ChatTabIcon(unread: unread, filled: true),
        inactiveIcon: _ChatTabIcon(unread: unread, filled: false),
        activeColorPrimary: accent,
        inactiveColorPrimary: inactive,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.play_circle_filled),
        inactiveIcon: const Icon(Icons.play_circle_outline),
        activeColorPrimary: accent,
        inactiveColorPrimary: inactive,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        inactiveIcon: const Icon(Icons.person_outline),
        activeColorPrimary: accent,
        inactiveColorPrimary: inactive,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.uid : '';
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final accent = AppColors.accent;
    final inactive = Theme.of(context).bottomNavigationBarTheme.unselectedItemColor
        ?? AppColors.neutral400;

    return BlocProvider<ConversationsBloc>(
      create: (ctx) => ConversationsBloc(
        repository: ctx.read<ChatRepository>(),
        currentUserId: currentUserId,
      )..add(const ConversationsLoadRequested()),
      child: BlocBuilder<ConversationsBloc, ConversationsState>(
        buildWhen: (a, b) {
          final ua = a is ConversationsLoaded ? a.totalUnread : 0;
          final ub = b is ConversationsLoaded ? b.totalUnread : 0;
          return ua != ub;
        },
        builder: (context, convState) {
          final unread =
              convState is ConversationsLoaded ? convState.totalUnread : 0;
          return AppTabController(
            controller: _controller,
            child: PersistentTabView(
              context,
              controller: _controller,
              screens: _buildScreens(),
              items: _buildNavItems(unread, accent, inactive),
              handleAndroidBackButtonPress: true,
              resizeToAvoidBottomInset: true,
              stateManagement: true,
              popBehaviorOnSelectedNavBarItemPress: PopBehavior.once,
              backgroundColor: surfaceColor,
              navBarStyle: NavBarStyle.style3,
            ),
          );
        },
      ),
    );
  }
}

/// Chat tab icon with an unread count badge.
class _ChatTabIcon extends StatelessWidget {
  final int unread;
  final bool filled;

  const _ChatTabIcon({required this.unread, required this.filled});

  @override
  Widget build(BuildContext context) {
    // SizedBox fixes the layout footprint to match a plain Icon so the nav bar
    // doesn't shift this item relative to its neighbours.
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Icon(filled ? Icons.chat_bubble : Icons.chat_bubble_outline),
          if (unread > 0)
            Positioned(
              top: 1,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints:
                    const BoxConstraints(minWidth: 13, minHeight: 13),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                    fontSize: 7,
                    color: AppColors.onAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
