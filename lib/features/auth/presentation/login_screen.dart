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
        
        if (errorString.contains('network') || errorString.contains('connection')) {
          errorMsg = 'Network error. Please check your internet connection.';
        } else if (errorString.contains('cancelled') || errorString.contains('canceled')) {
          return;
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
    final theme = Theme.of(context);

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
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: _LogoSection()),
                      const SizedBox(height: 64),

                      Text(
                        'Welcome to Hisabi 👋',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          color: context.onSurfaceColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'The most frictionless receipt tracking app in the world.\n\nBuilt so you stick with it.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: context.onSurfaceMutedColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 64),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 14),
                          ),
                        ),
                      ],

                      // Official style Apple Button
                      _BrandedSignInButton(
                        onPressed: () {},
                        icon: Icons.apple,
                        label: 'Continue with Apple',
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      
                      // Official style Google Button
                      _BrandedSignInButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        iconWidget: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_\"G\"_logo.svg/1200px-Google_\"G\"_logo.svg.png',
                          width: 20,
                          height: 20,
                        ),
                        label: 'Continue with Google',
                        backgroundColor: Colors.white,
                        textColor: Colors.black,
                        showLoader: _isLoading,
                      ),
                      
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: Divider(color: context.borderColor.withOpacity(0.3))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or', style: TextStyle(color: context.onSurfaceMutedColor)),
                          ),
                          Expanded(child: Divider(color: context.borderColor.withOpacity(0.3))),
                        ],
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            elevation: 0,
                          ),
                          child: const Text('Continue with Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Already have an account? Log in',
                            style: TextStyle(
                              color: context.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _BrandedSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool showLoader;

  const _BrandedSignInButton({
    required this.onPressed,
    this.icon,
    this.iconWidget,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: backgroundColor == Colors.white 
                ? BorderSide(color: Colors.grey.shade300) 
                : BorderSide.none,
          ),
        ),
        child: showLoader
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, 
                  valueColor: AlwaysStoppedAnimation<Color>(textColor)
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (iconWidget != null) iconWidget!,
                  if (icon != null) Icon(icon, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    label, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        'lib/assets/logo.svg',
        width: 120,
        height: 120,
      ),
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

    for (int i = 0; i < 3; i++) {
      final offset = animationValue * 2 * math.pi + (i * 2 * math.pi / 3);
      final x = size.width * 0.5 + math.cos(offset) * size.width * 0.3;
      final y = size.height * 0.2 + math.sin(offset) * size.height * 0.1;

      final radius = 150 + math.sin(animationValue * 2 * math.pi + i) * 50;
      final opacity = 0.03 + math.sin(animationValue * 2 * math.pi + i) * 0.01;

      paint.color = AppColors.primary.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => true;
}
