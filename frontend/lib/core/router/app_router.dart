import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

// Auth screens
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/profile_setup_screen.dart';

// Shell + tabs
import '../../features/home/app_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/shorts/shorts_screen.dart';
import '../../features/battle/learning_battle_screen.dart';
import '../../features/battle/battle_quiz_screen.dart';
import '../../features/vault/my_learning_vault_screen.dart';
import '../../features/profile/profile_screen.dart';

// Player
import '../../features/player/lecture_detail_screen.dart';
import '../../features/player/video_player_screen.dart';

// Feature screens
import '../../features/search/search_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/settings/settings_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Whether the user is authenticated (token in memory).
bool get _isAuth => true; // ApiService.instance.hasToken;

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    final isAuth  = _isAuth;
    final loc     = state.matchedLocation;
    final onAuth  = loc.startsWith('/login') ||
                    loc.startsWith('/signup') ||
                    loc.startsWith('/otp') ||
                    loc.startsWith('/setup') ||
                    loc.startsWith('/splash') ||
                    loc.startsWith('/onboarding');

    if (!isAuth && !onAuth) return '/login';
    if (isAuth && onAuth)  return '/home';
    return null;
  },
  routes: [
    // ── Splash / Onboarding ────────────────────────────────────────────
    GoRoute(path: '/splash',     builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const SplashScreen()),

    // ── Auth ───────────────────────────────────────────────────────────
    GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(
      path: '/otp',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return OtpScreen(
          phoneNumber: extra['phone'] as String? ?? '',
          userName:    extra['name']  as String?,
        );
      },
    ),
    GoRoute(
      path: '/setup',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ProfileSetupScreen(userName: extra['name'] as String?);
      },
    ),

    // ── Main shell (bottom nav) ─────────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home',         builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/home/battle',  builder: (_, __) => const LearningBattlefieldScreen()),
        GoRoute(path: '/home/shorts',  builder: (_, __) => const ShortsScreen()),
        GoRoute(path: '/home/vault',   builder: (_, __) => const MyLearningVaultScreen()),
        GoRoute(path: '/home/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // ── Battle quiz (full-screen, outside shell) ────────────────────────
    GoRoute(
      path: '/battle/quiz',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return BattleQuizScreen(
          attemptId: extra['attempt_id'] as String? ?? '',
          questions: (extra['questions'] as List?)
              ?.cast<Map<String, dynamic>>() ?? [],
        );
      },
    ),

    // ── Lecture detail (full-screen) ───────────────────────────────────────────
    GoRoute(
      path: '/lecture/:id',
      builder: (_, state) => LectureDetailScreen(courseId: state.pathParameters['id']!),
    ),

    // ── Vault (full-screen, accepts subject extra) ──────────────────────────────
    // Navigated from Home: context.push('/vault', extra: {'subject': name})
    GoRoute(
      path: '/vault',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return MyLearningVaultScreen(
          initialSubject: extra['subject'] as String?,
        );
      },
    ),

    // ── Video player (full-screen) ──────────────────────────────────────
    GoRoute(
      path: '/player/:lessonId',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return VideoPlayerScreen(lessonData: extra);
      },
    ),

    // ── Search ────────────────────────────────────────────────────────────
    GoRoute(path: '/search',        builder: (_, __) => const SearchScreen()),

    // ── Notifications ─────────────────────────────────────────────────────
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),

    // ── Settings ──────────────────────────────────────────────────────────
    GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
  ],
);
