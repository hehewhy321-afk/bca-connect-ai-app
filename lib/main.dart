import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/modern_theme.dart';
import 'core/services/cache_service.dart';
import 'core/services/notification_service.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/widgets/offline_indicator.dart';

// Background message handler must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
  
  // Show notification
  final notification = message.notification;
  if (notification != null) {
    await NotificationService().showNotification(
      title: notification.title ?? 'New Notification',
      body: notification.body ?? '',
      payload: message.data['route'],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');
    
    // Initialize Hive for local storage
    await Hive.initFlutter();
    
    // Initialize Cache Service
    await CacheService().initialize();
    
    // Initialize Supabase
    await SupabaseConfig.initialize();
    
    // Initialize Firebase for push notifications & analytics
    try {
      await Firebase.initializeApp();
      
      // Initialize Firebase Analytics
      FirebaseAnalytics analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);
      debugPrint('Firebase Analytics initialized successfully');
      
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Initialize Notification Service
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Firebase initialization skipped: $e');
      // App will work without push notifications and analytics
    }
    
    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    debugPrint('Initialization error: $e');
    runApp(const ProviderScope(child: ErrorApp()));
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return ConnectivitySnackbar(
      child: MaterialApp.router(
        title: 'BCA MMAMC',
        debugShowCheckedModeBanner: false,
        theme: ModernTheme.lightTheme,
        darkTheme: ModernTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Please check your configuration'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
