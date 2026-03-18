import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context, {
  required String message,
  IconData? icon,
  Duration duration = const Duration(seconds: 2),
}) {
  final theme = Theme.of(context);

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: theme.colorScheme.onInverseSurface),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
}

