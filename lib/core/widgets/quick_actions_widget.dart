import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const QuickAction({
    required this.label,
    required this.icon,
    this.onTap,
    this.color,
  });
}

class QuickActionsWidget extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsWidget({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayActions = actions.take(4).toList(); // Max 4 actions

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: displayActions.map((action) {
                final index = displayActions.indexOf(action);
                return GestureDetector(
                  onTap: action.onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (action.color ?? colorScheme.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (action.color ?? colorScheme.primary).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          action.icon,
                          color: action.color ?? colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: Duration(milliseconds: index * 50)).fadeIn().scale(begin: const Offset(0.8, 0.8));
              }).toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
