import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/battle/learning_battle_screen.dart';
import '../../features/home/app_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/profile_setup_screen.dart';
import '../../features/player/video_player_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shorts/shorts_screen.dart';
import '../../features/splash/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) => const VideoPlayerScreen(),
    ),

    // Shell route — home with bottom nav
    ShellRoute(
      builder: (context, state, child) {
        final loc = state.uri.path;
        int index = 0;
        if (loc.startsWith('/home/shorts')) index = 1;
        if (loc.startsWith('/home/battle')) index = 2;
        if (loc.startsWith('/home/profile')) index = 3;
        return AppShell(currentIndex: index, child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          redirect: (_, __) => '/home/feed',
        ),
        GoRoute(
          path: '/home/feed',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/home/shorts',
          builder: (context, state) => const ShortsScreen(),
        ),
        GoRoute(
          path: '/home/battle',
          builder: (context, state) => const LearningBattleScreen(),
        ),
        GoRoute(
          path: '/home/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
