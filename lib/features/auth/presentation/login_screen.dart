import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/auth/providers/auth_provider.dart';
import 'package:hisabi/core/constants/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  late final AnimationController _backgroundController;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await ref.read(authProvider.notifier).loginWithGoogle();
      
      if (mounted) {
        final authState = ref.read(authProvider);
        if (authState.status == AuthStatus.authenticated) {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to sign in with Google.';
        
        final errorString = e.toString().toLowerCase();
        print('Google Sign-In Error Details: $e');
        
        if (errorString.contains('network') || errorString.contains('connection')) {
          errorMsg = 'Network error. Please check your internet connection.';
        } else if (errorString.contains('cancelled') || errorString.contains('canceled')) {
          errorMsg = 'Sign-in was cancelled.';
          return;
        } else if (errorString.contains('oauth') || errorString.contains('client') || errorString.contains('configuration')) {
          errorMsg = 'Google Sign-In not configured. Please ensure:\n1. Google Sign-In is enabled in Firebase Console\n2. SHA-1 fingerprint is added to Firebase\n3. OAuth client is configured for Android';
        } else if (errorString.contains('firebase') || errorString.contains('auth')) {
          errorMsg = 'Firebase authentication error. Please try again.';
        } else if (errorString.contains('sign_in_failed') || errorString.contains('platform_exception')) {
          errorMsg = 'Google Sign-In failed. Check Firebase configuration.';
        }
        
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          _AnimatedBackground(controller: _backgroundController),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 420,
                      minHeight: size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LogoSection(),
                        const SizedBox(height: 48),

                        Text(
                          'Welcome to Hisabi',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                            color: context.onSurfaceColor,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'AI-Powered Receipt Analysis\nTrack your expenses effortlessly',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: context.onSurfaceMutedColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Icon(
                                          Icons.g_mobiledata,
                                          color: context.primaryColor,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _FeaturesList(),
                        const SizedBox(height: 32),

                        Text(
                          'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.onSurfaceMutedColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'lib/assets/logo.svg',
      width: 180,
      height: 180,
    );
  }
}

class _FeaturesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      {'icon': Icons.auto_awesome, 'text': 'AI-Powered Analysis'},
      {'icon': Icons.mic_outlined, 'text': 'Voice Quick Add'},
      {'icon': Icons.analytics_outlined, 'text': 'Smart Analytics'},
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                feature['text'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.onSurfaceMutedColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundPainter(animationValue: controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animationValue;

  _BackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Gradient circles that move
    for (int i = 0; i < 4; i++) {
      final offset = animationValue * 2 * math.pi + (i * 2 * math.pi / 4);
      final x = size.width * 0.5 +
          math.cos(offset) * size.width * 0.4;
      final y = size.height * 0.5 +
          math.sin(offset) * size.height * 0.3;

      final radius = 100 + math.sin(animationValue * 2 * math.pi + i) * 40;
      final opacity = 0.04 + math.sin(animationValue * 2 * math.pi + i) * 0.02;

      paint.color = AppColors.primary.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Floating particles
    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final seed = i * 100;
      final x = (random.nextDouble() * size.width +
              math.sin(animationValue * 2 * math.pi + seed) * 60) %
          size.width;
      final y = (random.nextDouble() * size.height +
              math.cos(animationValue * 2 * math.pi + seed) * 40) %
          size.height;

      final particleSize = 3 + math.sin(animationValue * 2 * math.pi + seed) * 1.5;
      final opacity = 0.08 + math.sin(animationValue * 2 * math.pi + seed) * 0.04;

      paint.color = AppColors.primary.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
