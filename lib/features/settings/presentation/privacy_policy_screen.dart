import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                'Privacy Policy',
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
              title: '1. Information We Collect',
              content:
                  'Hisabi collects and stores the following information locally on your device:\n\n'
                  '• Receipt data (amounts, items, dates, stores)\n'
                  '• User preferences (currency, naming format, theme)\n'
                  '• Authentication information (email, name, profile picture)',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '2. Data Storage',
              content:
                  'All data is stored locally on your device using secure local storage. '
                  'We do not transmit your receipt data to external servers unless you explicitly '
                  'choose to sync with a backend service.',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '3. Data Usage',
              content:
                  'Your data is used solely to provide the receipt tracking and analysis features. '
                  'We do not sell, share, or use your data for advertising purposes.',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '4. Third-Party Services',
              content:
                  'Hisabi uses Google Sign-In for authentication. When you sign in with Google, '
                  'we receive your email address, name, and profile picture. This information is stored '
                  'locally and used only for authentication purposes.',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '5. Data Export and Deletion',
              content:
                  'You can export your data at any time through the Settings screen. '
                  'You can also delete all data using the "Clear All Data" option in Settings.',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '6. Changes to This Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any '
                  'changes by updating the "Last updated" date at the top of this policy.',
            ),
            const SizedBox(height: 24),
            const _Section(
              title: '7. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy, please contact us through '
                  'the app settings or support channels.',
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
