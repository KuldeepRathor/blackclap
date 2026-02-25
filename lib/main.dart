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
import 'views/screens/main/stories_screen.dart';
import 'views/screens/main/reels_screen.dart';
import 'views/screens/main/notifications_screen.dart';
import 'views/screens/main/messages_screen.dart';
import 'views/screens/main/chat_screen.dart';
import 'views/screens/main/post_detail_screen.dart';
import 'views/screens/main/user_profile_screen.dart';
import 'views/screens/main/edit_profile_screen.dart';
import 'views/screens/main/settings_screen.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/posts/posts_bloc.dart';
import 'blocs/reels/reels_bloc.dart';
import 'blocs/theme/theme_bloc.dart';
import 'blocs/theme/theme_state.dart';
import 'repositories/user_repository.dart';
import 'repositories/post_repository.dart';
import 'constants/color_constants.dart';
import 'constants/app_text_styles.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BlackClapApp());
}

/// Notifier that bridges AuthBloc state changes to GoRouter refresh.
class RouterNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;

  RouterNotifier(this._authBloc) {
    _authBloc.stream.listen((_) => notifyListeners());
  }
}

class BlackClapApp extends StatefulWidget {
  const BlackClapApp({super.key});

  @override
  State<BlackClapApp> createState() => _BlackClapAppState();
}

class _BlackClapAppState extends State<BlackClapApp> {
  late final AuthBloc _authBloc;
  late final RouterNotifier _routerNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(userRepository: UserRepository())
      ..add(AuthCheckRequested());
    _routerNotifier = RouterNotifier(_authBloc);

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: _routerNotifier,
      redirect: (context, routerState) {
        final authState = _authBloc.state;
        final isAuthenticated = authState is AuthAuthenticated;
        final isOnAuthPage = routerState.uri.path == '/login' ||
            routerState.uri.path == '/signup';

        if (!isAuthenticated && !isOnAuthPage) return '/login';
        if (isAuthenticated && isOnAuthPage) return '/home';
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
          path: '/stories',
          builder: (context, state) => const StoriesScreen(),
        ),
        GoRoute(
          path: '/reels',
          builder: (context, state) => const ReelsScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesScreen(),
        ),
        GoRoute(
          path: '/chat/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return ChatScreen(otherUserId: userId);
          },
        ),
        GoRoute(
          path: '/post/:postId',
          builder: (context, state) {
            final postId = state.pathParameters['postId']!;
            return PostDetailScreen(postId: postId);
          },
        ),
        GoRoute(
          path: '/user/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return UserProfileScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _routerNotifier.dispose();
    _authBloc.close();
    super.dispose();
  }

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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<PostsBloc>(create: (context) => PostsBloc()),
          BlocProvider<ReelsBloc>(create: (context) => ReelsBloc()),
          BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Blackclap',
              themeMode: themeState.themeMode,
              theme: _buildLightTheme(),
              darkTheme: _buildDarkTheme(),
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: AppColorScheme.lightScheme,
      brightness: Brightness.light,
      useMaterial3: true,
      textTheme: AppTextStyles.textTheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.neutral400,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
        hintStyle: TextStyle(color: AppColors.neutral400),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
      ),
      brightness: Brightness.dark,
      useMaterial3: true,
      textTheme: AppTextStyles.textTheme,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1A1A1A),
        elevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
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
      const CreatePostScreen(),
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
        icon: const Icon(Icons.add_box),
        inactiveIcon: const Icon(Icons.add_box_outlined),
        activeColorPrimary: AppColors.accent,
        inactiveColorPrimary: AppColors.neutral400,
        iconSize: 38,
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
      backgroundColor: AppColors.primary,
      navBarStyle: NavBarStyle.style12,
    );
  }
}
