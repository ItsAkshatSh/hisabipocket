import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/features/wrapped/providers/wrapped_provider.dart';
import 'package:hisabi/features/wrapped/models/wrapped_models.dart';

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
    
    return Scaffold(
      backgroundColor: Colors.black,
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
              bottom: 100,
              left: 20,
              right: 20,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage == wrapped.cards.length - 1)
                      _buildShareButton(wrapped),
                    if (_currentPage == wrapped.cards.length - 1)
                      _buildDoneButton(),
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
    return FloatingActionButton.extended(
      heroTag: 'share',
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share feature coming soon!')),
        );
      },
      backgroundColor: Colors.white,
      label: const Text('Share', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.share, color: Colors.black),
    );
  }

  Widget _buildDoneButton() {
    return FloatingActionButton.extended(
      heroTag: 'done',
      onPressed: () => context.go('/dashboard'),
      backgroundColor: Colors.white,
      label: const Text('Finish', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.check, color: Colors.black),
    );
  }
  
  Widget _buildLoadingScreen() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
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
  
  const _WrappedCardWidget({required this.card, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [card.backgroundColor, card.backgroundColor.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (card.emoji != null)
                FadeTransition(opacity: animation, child: Text(card.emoji!, style: const TextStyle(fontSize: 80))),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: animation,
                child: Text(card.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: card.textColor), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 32),
              ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
                child: Text(card.mainValue, style: TextStyle(fontSize: card.type == CardType.totalSpent ? 64 : 48, fontWeight: FontWeight.bold, color: card.textColor, letterSpacing: -2), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: animation,
                child: Text(card.subtitle, style: TextStyle(fontSize: 18, color: card.textColor.withOpacity(0.9)), textAlign: TextAlign.center),
              ),
              if (card.secondaryValue != null) ...[
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: animation,
                  child: Text(card.secondaryValue!, style: TextStyle(fontSize: 16, color: card.textColor.withOpacity(0.8)), textAlign: TextAlign.center),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
