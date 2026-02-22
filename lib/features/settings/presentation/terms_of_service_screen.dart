import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20.0 : 32.0,
          vertical: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) => Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                  color: context.onSurfaceColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 14,
                color: context.onSurfaceMutedColor,
              ),
            ),
            const SizedBox(height: 32),
            const _Section(
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using Hisabi, you accept and agree to be bound by the terms '
                  'and provision of this agreement.',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '2. Use License',
              content:
                  'Permission is granted to temporarily use Hisabi for personal, non-commercial '
                  'transitory viewing only. This is the grant of a license, not a transfer of title, '
                  'and under this license you may not:\n\n'
                  '• Modify or copy the materials\n'
                  '• Use the materials for any commercial purpose\n'
                  '• Attempt to reverse engineer any software contained in the app',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '3. User Responsibilities',
              content: 'You are responsible for:\n\n'
                  '• Maintaining the confidentiality of your account\n'
                  '• All activities that occur under your account\n'
                  '• Ensuring the accuracy of receipt data you enter\n'
                  '• Backing up your data regularly',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '4. Service Availability',
              content:
                  'We strive to provide a reliable service, but we do not guarantee that the app '
                  'will be available at all times. The app may be unavailable due to maintenance, updates, '
                  'or unforeseen circumstances.',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '5. Data Accuracy',
              content:
                  'While we provide tools to help you track receipts, you are responsible for '
                  'verifying the accuracy of all data entered. We are not liable for any errors in '
                  'receipt data or calculations.',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '6. Limitation of Liability',
              content:
                  'In no event shall Hisabi or its suppliers be liable for any damages arising '
                  'out of the use or inability to use the app, even if we have been notified of the '
                  'possibility of such damage.',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '7. Changes to Terms',
              content:
                  'We reserve the right to modify these terms at any time. We will notify users '
                  'of any material changes by updating the "Last updated" date.',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '8. Termination',
              content:
                  'We may terminate or suspend your access to the app immediately, without prior '
                  'notice, for conduct that we believe violates these Terms of Service.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.onSurfaceColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: context.onSurfaceMutedColor,
          ),
        ),
      ],
    );
  }
}
