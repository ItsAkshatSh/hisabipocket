import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/features/wrapped/providers/wrapped_provider.dart';
import 'package:hisabi/features/wrapped/models/wrapped_models.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/core/constants/app_theme.dart';

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
    
    final bgColor = themeSelection == AppThemeSelection.classic ? Colors.black : _getThemeBaseColor(themeSelection);

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
                
                // If it's the first page, mark as viewed for this week
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
                  icon: const Icon(Icons.close, color: Colors.white),
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
  
  Color _getThemeBaseColor(AppThemeSelection selection) {
    switch (selection) {
      case AppThemeSelection.classic: return Colors.black;
      case AppThemeSelection.midnight: return const Color(0xFF0F172A);
      case AppThemeSelection.forest: return const Color(0xFF022C22);
      case AppThemeSelection.sunset: return const Color(0xFF451A03);
      case AppThemeSelection.lavender: return const Color(0xFF0C0A09);
      case AppThemeSelection.monochrome: return const Color(0xFF121212);
    }
  }

  Widget _buildProgressIndicator(int totalCards) {
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
              color: _currentPage == index ? Colors.white : Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildShareButton(WeekWrapped wrapped) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share feature coming soon!')),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      label: const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.share, size: 20),
    );
  }

  Widget _buildDoneButton() {
    return ElevatedButton.icon(
      onPressed: () => context.go('/dashboard'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      label: const Text('Finish', style: TextStyle(fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.check, size: 20),
    );
  }
  
  Widget _buildLoadingScreen() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }
  
  Future<void> _markWrappedAsViewed() async {
    try {
      final now = DateTime.now();
      final daysToSubtract = now.weekday == 7 ? 0 : now.weekday;
      final sunday = now.subtract(Duration(days: daysToSubtract));
      final sundayStart = DateTime(sunday.year, sunday.month, sunday.day);
      final weekId = 'wrapped_${sundayStart.year}_${sundayStart.month}_${sundayStart.day}';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_wrapped_week_id', weekId);
    } catch (e) {}
  }
  
  Widget _buildErrorScreen(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          const Text('Error loading wrapped', style: TextStyle(color: Colors.white, fontSize: 18)),
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
    final startColor = themeSelection == AppThemeSelection.classic 
        ? card.backgroundColor 
        : Theme.of(context).colorScheme.primary;
        
    final endColor = themeSelection == AppThemeSelection.classic 
        ? card.backgroundColor.withOpacity(0.7)
        : Theme.of(context).colorScheme.secondary.withOpacity(0.8);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [startColor, endColor],
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
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: animation,
                child: Text(
                  card.subtitle, 
                  style: const TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.w800, 
                    color: Colors.white,
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
                      color: Colors.white, 
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
                      color: Colors.white.withOpacity(0.8),
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
}
