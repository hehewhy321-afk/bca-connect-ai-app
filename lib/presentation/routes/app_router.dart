import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/supabase_config.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/modern_login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/forum/create_post_screen.dart';
import '../screens/forum/enhanced_forum_screen.dart';
import '../screens/forum/enhanced_forum_post_detail_screen.dart';
import '../screens/certificates/certificates_screen.dart';
import '../screens/resources/enhanced_resources_screen.dart';
import '../screens/resources/resource_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/ai/improved_ai_assistant_screen.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/alumni/alumni_screen.dart';
import '../screens/settings/enhanced_settings_screen.dart';
import '../screens/notices/enhanced_notices_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/debug/event_debug_screen.dart';
import '../screens/events/enhanced_events_screen.dart';
import '../screens/events/enhanced_event_detail_screen.dart';
import '../screens/events/my_events_screen.dart';
import '../screens/calendar/nepali_calendar_screen.dart';
import '../screens/pomodoro/pomodoro_screen.dart';
import '../screens/finance/finance_tracker_screen.dart';
import '../screens/study/study_planner_screen.dart';
import '../screens/algorithm_game/algorithm_game_home_screen.dart';
import '../screens/fun_zone/fun_zone_home_screen.dart';
import '../screens/courses/courses_screen.dart';
import '../screens/courses/course_detail_screen.dart';
import '../screens/courses/learning_player_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = SupabaseConfig.client.auth.currentUser != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplashRoute = state.matchedLocation == '/';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      
      // Allow splash and onboarding routes to handle their own navigation
      if (isSplashRoute || isOnboardingRoute) {
        return null;
      }
      
      // If not authenticated and not on auth route, redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }
      
      // If authenticated and on auth route, redirect to home
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Auth Routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const ModernLoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Main App Routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Events
      GoRoute(
        path: '/events',
        builder: (context, state) => const EnhancedEventsScreen(),
      ),
      GoRoute(
        path: '/events/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EnhancedEventDetailScreen(eventId: id);
        },
      ),
      
      // My Events
      GoRoute(
        path: '/my-events',
        builder: (context, state) => const MyEventsScreen(),
      ),
      
      // Forum
      GoRoute(
        path: '/forum',
        builder: (context, state) => const EnhancedForumScreen(),
      ),
      GoRoute(
        path: '/forum/create',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/forum/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EnhancedForumPostDetailScreen(postId: id);
        },
      ),
      
      // Certificates
      GoRoute(
        path: '/certificates',
        builder: (context, state) => const CertificatesScreen(),
      ),
      
      // Resources
      GoRoute(
        path: '/resources',
        builder: (context, state) => const EnhancedResourcesScreen(),
      ),
      GoRoute(
        path: '/resources/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ResourceDetailScreen(resourceId: id);
        },
      ),
      
      // Profile
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // AI Assistant
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const ImprovedAIAssistantScreen(),
      ),
      
      // Achievements
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      
      // Community
      GoRoute(
        path: '/community',
        builder: (context, state) => const CommunityScreen(),
      ),
      
      // Alumni
      GoRoute(
        path: '/alumni',
        builder: (context, state) => const AlumniScreen(),
      ),
      
      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const EnhancedSettingsScreen(),
      ),
      
      // Notices
      GoRoute(
        path: '/notices',
        builder: (context, state) => const EnhancedNoticesScreen(),
      ),
      
      // Notification Settings
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      
      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      
      // Nepali Calendar
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const NepaliCalendarScreen(),
      ),
      
      // Pomodoro Timer
      GoRoute(
        path: '/pomodoro',
        builder: (context, state) => const PomodoroScreen(),
      ),
      
      // Finance Tracker
      GoRoute(
        path: '/finance',
        builder: (context, state) => const FinanceTrackerScreen(),
      ),
      
      // Study Planner
      GoRoute(
        path: '/study',
        builder: (context, state) => const StudyPlannerScreen(),
      ),
      
      // Algorithm Game
      GoRoute(
        path: '/algorithm-game',
        builder: (context, state) => const AlgorithmGameHomeScreen(),
      ),
      
      // Fun Zone
      GoRoute(
        path: '/fun-zone',
        builder: (context, state) => const FunZoneHomeScreen(),
      ),
      
      // Courses
      GoRoute(
        path: '/courses',
        builder: (context, state) => const CoursesScreen(),
      ),
      GoRoute(
        path: '/courses/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CourseDetailScreen(courseId: id);
        },
      ),
      GoRoute(
        path: '/courses/:id/learn',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LearningPlayerScreen(courseId: id);
        },
      ),
      
      // Debug
      GoRoute(
        path: '/debug/events',
        builder: (context, state) => const EventDebugScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
