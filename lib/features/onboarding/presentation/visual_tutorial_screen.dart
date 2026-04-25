import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/core/services/onboarding_service.dart';

class VisualTutorialScreen extends ConsumerWidget {
  const VisualTutorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 32),
              Text(
                'Welcome to Hisabi',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Track your spending effortlessly with AI-powered OCR and voice commands.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await OnboardingService.setSeenOnboarding();
                  if (context.mounted) {
                    context.go('/quick-start');
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
