import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';

class VoiceQuickAddScreen extends StatelessWidget {
  const VoiceQuickAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.onSurfaceColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              size: 64,
              color: context.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Voice Quick Add',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: context.onSurfaceColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(
                fontSize: 14,
                color: context.onSurfaceMutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
