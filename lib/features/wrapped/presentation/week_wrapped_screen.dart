import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
            // Full-screen card viewer
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _animationController.reset();
                _animationController.forward();
                
                // Mark as viewed when user starts viewing
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
            
            // Progress indicator
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: _buildProgressIndicator(wrapped.cards.length),
            ),
            
            // Back button
            Positioned(
              top: 50,
              left: 20,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            
            // Share button (on last card)
            if (_currentPage == wrapped.cards.length - 1)
              Positioned(
                bottom: 40,
                right: 20,
                child: _buildShareButton(wrapped),
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
      onPressed: () {
        // TODO: Implement share functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share feature coming soon!'),
            backgroundColor: Colors.black87,
          ),
        );
      },
      backgroundColor: Colors.white,
      icon: const Icon(Icons.share, color: Colors.black),
      label: const Text(
        'Share',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
        ),
      ),
    );
  }
  
  Future<void> _markWrappedAsViewed() async {
    try {
      final box = await Hive.openBox('app_preferences');
      await box.put('last_wrapped_view', DateTime.now().toIso8601String());
    } catch (e) {
      // Silently fail
    }
  }
  
  Widget _buildErrorScreen(Object error) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              'Error loading your wrapped',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WrappedCardWidget extends StatelessWidget {
  final WrappedCard card;
  final AnimationController animation;
  
  const _WrappedCardWidget({
    required this.card,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card.backgroundColor,
            card.backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji (if present)
              if (card.emoji != null)
                FadeTransition(
                  opacity: animation,
                  child: Text(
                    card.emoji!,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Title
              FadeTransition(
                opacity: animation,
                child: Text(
                  card.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: card.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Main Value
              ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: Text(
                  card.mainValue,
                  style: TextStyle(
                    fontSize: card.type == CardType.totalSpent ? 64 : 48,
                    fontWeight: FontWeight.bold,
                    color: card.textColor,
                    letterSpacing: -2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              FadeTransition(
                opacity: animation,
                child: Text(
                  card.subtitle,
                  style: TextStyle(
                    fontSize: 18,
                    color: card.textColor.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Secondary value
              if (card.secondaryValue != null) ...[
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: animation,
                  child: Text(
                    card.secondaryValue!,
                    style: TextStyle(
                      fontSize: 16,
                      color: card.textColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              
              // Highlights
              if (card.highlights != null) ...[
                const SizedBox(height: 32),
                ...card.highlights!.map((highlight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FadeTransition(
                    opacity: animation,
                    child: Text(
                      highlight,
                      style: TextStyle(
                        fontSize: 16,
                        color: card.textColor.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

