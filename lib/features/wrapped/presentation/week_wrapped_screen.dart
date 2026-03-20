import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/features/wrapped/providers/wrapped_provider.dart';
import 'package:hisabi/features/wrapped/models/wrapped_models.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

class WeekWrappedScreen extends ConsumerStatefulWidget {
  final DateTime? weekStart;
  
  const WeekWrappedScreen({super.key, this.weekStart});

  @override
  ConsumerState<WeekWrappedScreen> createState() => _WeekWrappedScreenState();
}

class _WeekWrappedScreenState extends ConsumerState<WeekWrappedScreen> 
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wrappedAsync = ref.watch(weekWrappedProvider(widget.weekStart));
    final settingsAsync = ref.watch(settingsProvider);
    final themeSelection = settingsAsync.valueOrNull?.themeSelection ?? AppThemeSelection.classic;
    
    final cs = Theme.of(context).colorScheme;
    final bgColor = cs.surface;

    return Scaffold(
      backgroundColor: bgColor,
      body: wrappedAsync.when(
        data: (wrapped) => Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _animationController.reset();
                _animationController.forward();
                
                if (index == 0) {
                  _markWrappedAsViewed();
                }
              },
              itemCount: wrapped.cards.length,
              itemBuilder: (context, index) {
                return _WrappedCardWidget(
                  card: wrapped.cards[index],
                  animation: _animationController,
                  themeSelection: themeSelection,
                );
              },
            ),
            
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: _buildProgressIndicator(wrapped.cards.length),
            ),
            
            Positioned(
              top: 50,
              left: 20,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(Icons.close, color: cs.onSurface),
                  onPressed: () => context.go('/dashboard'),
                ),
              ),
            ),
            
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage == wrapped.cards.length - 1)
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildShareButton(wrapped)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildDoneButton()),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => _buildLoadingScreen(),
        error: (e, s) => _buildErrorScreen(e),
      ),
    );
  }

  Widget _buildProgressIndicator(int totalCards) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalCards, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 4,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? cs.onSurface
                  : cs.onSurfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildShareButton(WeekWrapped wrapped) {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share feature coming soon!')),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.surfaceContainerHighest.withOpacity(0.7),
        foregroundColor: cs.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      label: const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.share, size: 20),
    );
  }

  Widget _buildDoneButton() {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: () => context.go('/dashboard'),
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      label: const Text('Finish', style: TextStyle(fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.check, size: 20),
    );
  }
  
  Widget _buildLoadingScreen() {
    final cs = Theme.of(context).colorScheme;
    return Center(child: CircularProgressIndicator(color: cs.primary));
  }
  
  Future<void> _markWrappedAsViewed() async {
    try {
      final box = await Hive.openBox('app_preferences');
      final now = DateTime.now();
      
      final daysToSubtract = now.weekday == 7 ? 0 : now.weekday;
      final sunday = now.subtract(Duration(days: daysToSubtract));
      final sundayStart = DateTime(sunday.year, sunday.month, sunday.day);
      
      final weekId = '${sundayStart.year}-${sundayStart.month.toString().padLeft(2, '0')}-${sundayStart.day.toString().padLeft(2, '0')}';
      
      await box.put('last_wrapped_week_id', weekId);
      await box.put('last_wrapped_view', now.toIso8601String());
    } catch (e) {}
  }
  
  Widget _buildErrorScreen(Object error) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 64),
          const SizedBox(height: 16),
          Text('Error loading wrapped', style: TextStyle(color: cs.onSurface, fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Go Back to Dashboard'),
          ),
        ],
      ),
    );
  }
}

class _WrappedCardWidget extends StatelessWidget {
  final WrappedCard card;
  final AnimationController animation;
  final AppThemeSelection themeSelection;
  
  const _WrappedCardWidget({
    required this.card, 
    required this.animation,
    required this.themeSelection,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = _paletteFor(card.type, cs);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.start, palette.end],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: animation,
                child: Text(
                  card.title.toUpperCase(), 
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w900, 
                    color: palette.on.withOpacity(0.75),
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: animation,
                child: Text(
                  card.subtitle, 
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.w800, 
                    color: palette.on,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut)
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    card.mainValue, 
                    style: TextStyle(
                      fontSize: card.type == CardType.totalSpent ? 72 : 56, 
                      fontWeight: FontWeight.w900, 
                      color: palette.on, 
                      letterSpacing: -2,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              if (card.secondaryValue != null) ...[
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: animation,
                  child: Text(
                    card.secondaryValue!, 
                    style: TextStyle(
                      fontSize: 18, 
                      color: palette.on.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _WrappedPalette _paletteFor(CardType type, ColorScheme cs) {
    switch (type) {
      case CardType.opening:
        return _WrappedPalette(cs.primaryContainer, cs.primary, cs.onPrimaryContainer);
      case CardType.totalSpent:
        return _WrappedPalette(cs.secondaryContainer, cs.secondary, cs.onSecondaryContainer);
      case CardType.topCategory:
        return _WrappedPalette(cs.tertiaryContainer, cs.tertiary, cs.onTertiaryContainer);
      case CardType.topStore:
        return _WrappedPalette(cs.primary, cs.primaryContainer, cs.onPrimary);
      case CardType.biggestPurchase:
        return _WrappedPalette(cs.tertiary, cs.tertiaryContainer, cs.onTertiary);
      case CardType.busiestDay:
        return _WrappedPalette(cs.surfaceContainerHighest, cs.surfaceContainer, cs.onSurface);
      case CardType.personality:
        return _WrappedPalette(cs.secondary, cs.secondaryContainer, cs.onSecondary);
      case CardType.funFact:
        return _WrappedPalette(cs.errorContainer, cs.error, cs.onErrorContainer);
      case CardType.comparison:
        return _WrappedPalette(cs.surfaceContainerHighest, cs.surfaceContainerLow, cs.onSurface);
      case CardType.closing:
        return _WrappedPalette(cs.primaryContainer, cs.surface, cs.onPrimaryContainer);
    }
  }
}

class _WrappedPalette {
  final Color start;
  final Color end;
  final Color on;
  const _WrappedPalette(this.start, this.end, this.on);
}
