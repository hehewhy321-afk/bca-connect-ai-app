import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/supabase_config.dart';
import '../../../data/repositories/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      // Use SharedPreferences instead of Hive (clears on uninstall)
      final prefs = await SharedPreferences.getInstance();
      
      if (!mounted) return;
      
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      // If onboarding not completed, show onboarding
      if (!onboardingCompleted) {
        if (!mounted) return;
        context.go('/onboarding');
        return;
      }
      
      // Check if user is already authenticated
      bool isAuthenticated = SupabaseConfig.client.auth.currentUser != null;
      
      // If not authenticated, check for saved credentials and attempt auto-login
      if (!isAuthenticated) {
        final rememberMe = prefs.getBool('remember_me') ?? false;
        
        if (rememberMe) {
          final savedEmail = prefs.getString('saved_email') ?? '';
          final savedPassword = prefs.getString('saved_password') ?? '';
          
          if (savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
            try {
              // Attempt auto-login with saved credentials
              final authRepo = AuthRepository();
              await authRepo.signIn(savedEmail, savedPassword);
              isAuthenticated = true;
            } catch (e) {
              // If auto-login fails, clear saved credentials
              await prefs.remove('remember_me');
              await prefs.remove('saved_email');
              await prefs.remove('saved_password');
            }
          }
        }
      }
      
      if (!mounted) return;
      
      // Navigate based on authentication
      if (isAuthenticated) {
        context.go('/home');
      } else {
        context.go('/auth/login');
      }
    } catch (e) {
      // If any error occurs, go to onboarding (safe default for first install)
      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Image.asset(
                        'assets/images/pwa-512x512.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // App Name
                  Text(
                    'BCA MMAMC',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Tagline
                  Text(
                    'Student Association Platform',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
