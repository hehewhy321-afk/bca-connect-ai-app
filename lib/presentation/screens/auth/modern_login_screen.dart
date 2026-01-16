import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../widgets/gradient_button.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/theme/modern_theme.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class ModernLoginScreen extends ConsumerStatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  ConsumerState<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends ConsumerState<ModernLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signIn(_emailController.text.trim(), _passwordController.text);
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        // Show simple, user-friendly error message
        String errorMessage = 'Invalid email or password';
        
        // Check for specific error types
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Network error. Please check your connection';
        } else if (errorString.contains('email')) {
          errorMessage = 'Invalid email format';
        } else if (errorString.contains('banned') || errorString.contains('suspended')) {
          errorMessage = 'Your account has been suspended';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: isDark
            ? BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              )
            : const BoxDecoration(
                gradient: ModernTheme.orangeGradient,
              ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Iconsax.book,
                        size: 50,
                        color: ModernTheme.primaryOrange,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      'Welcome Back!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isDark 
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Sign in to continue',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Colors.white.withValues(alpha: 0.8),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    
                    const SizedBox(height: 48),
                    
                    // Login Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: const Icon(Iconsax.sms),
                              filled: true,
                              fillColor: isDark
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
                          
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Iconsax.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),
                          
                          const SizedBox(height: 12),
                          
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/auth/forgot-password'),
                              child: const Text('Forgot Password?'),
                            ),
                          ).animate().fadeIn(delay: 600.ms),
                          
                          const SizedBox(height: 24),
                          
                          // Login Button
                          GradientButton(
                            text: 'Sign In',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                            width: double.infinity,
                            icon: Iconsax.login,
                          ).animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.8, 0.8)),
                          
                          const SizedBox(height: 16),
                          
                          // Contact Admin Note
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Iconsax.info_circle, size: 20, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'New user? Contact admin for account creation',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 800.ms),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 24),
                    
                    // Guest Access
                    TextButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: Icon(
                        Iconsax.user,
                        color: isDark
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white,
                      ),
                      label: Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: isDark
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.white,
                        ),
                      ),
                    ).animate().fadeIn(delay: 900.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
