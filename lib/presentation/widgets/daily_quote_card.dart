import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/daily_quote.dart';
import '../../core/services/daily_quote_service.dart';
import '../../core/theme/modern_theme.dart';

class DailyQuoteCard extends StatefulWidget {
  const DailyQuoteCard({super.key});

  @override
  State<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends State<DailyQuoteCard> with SingleTickerProviderStateMixin {
  DailyQuote? _currentQuote;
  bool _isLoading = true;
  bool _isDismissed = false;
  double _dragOffset = 0;
  bool _isAnimating = false;
  
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _loadQuote();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    setState(() => _isLoading = true);
    final quote = await DailyQuoteService.getTodayQuote();
    if (mounted) {
      setState(() {
        _currentQuote = quote;
        _isLoading = false;
        _isDismissed = quote == null;
      });
    }
  }

  Future<void> _dismissQuote() async {
    await DailyQuoteService.dismissToday();
    if (mounted) {
      setState(() => _isDismissed = true);
    }
  }

  Future<void> _changeQuote(bool isNext) async {
    if (_isAnimating) return;
    
    setState(() => _isAnimating = true);
    
    // Animate out
    _slideAnimation = Tween<double>(
      begin: 0,
      end: isNext ? -1 : 1,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInCubic));
    
    await _slideController.forward();
    
    // Load new quote
    final quote = isNext 
        ? await DailyQuoteService.getNextQuote()
        : await DailyQuoteService.getPreviousQuote();
    
    if (mounted && quote != null) {
      setState(() => _currentQuote = quote);
      
      // Animate in from opposite side
      _slideController.reset();
      _slideAnimation = Tween<double>(
        begin: isNext ? 1 : -1,
        end: 0,
      ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
      
      await _slideController.forward();
    }
    
    if (mounted) {
      setState(() => _isAnimating = false);
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-100.0, 100.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isAnimating) return;
    
    final velocity = details.primaryVelocity ?? 0;
    
    if (_dragOffset.abs() > 50 || velocity.abs() > 500) {
      // Trigger swipe
      if (_dragOffset > 0 || velocity > 0) {
        _changeQuote(false); // Previous
      } else {
        _changeQuote(true); // Next
      }
    }
    
    // Reset drag offset
    setState(() => _dragOffset = 0);
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'study_tip':
        return const Color(0xFF3B82F6); // Blue
      case 'exam_advice':
        return const Color(0xFFEC4899); // Pink
      case 'motivation':
        return ModernTheme.primaryOrange; // Orange
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'study_tip':
        return Iconsax.book_1;
      case 'exam_advice':
        return Iconsax.clipboard_text;
      case 'motivation':
        return Iconsax.star5;
      default:
        return Iconsax.info_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_isDismissed || _currentQuote == null) {
      return const SizedBox.shrink();
    }

    final quote = _currentQuote!;
    final categoryColor = _getCategoryColor(quote.category);
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          final offset = _isAnimating 
              ? _slideAnimation.value * screenWidth 
              : _dragOffset;
          final opacity = _isAnimating
              ? (1 - _slideAnimation.value.abs()).clamp(0.0, 1.0)
              : (1 - (_dragOffset.abs() / 100)).clamp(0.3, 1.0);
          final scale = _isAnimating
              ? (1 - _slideAnimation.value.abs() * 0.1).clamp(0.9, 1.0)
              : (1 - (_dragOffset.abs() / 500)).clamp(0.95, 1.0);

          return Transform.translate(
            offset: Offset(offset, 0),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withValues(alpha: 0.1),
                        categoryColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Swipe indicators
                      if (_dragOffset.abs() > 20 && !_isAnimating)
                        Positioned.fill(
                          child: Row(
                            mainAxisAlignment: _dragOffset > 0
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: (_dragOffset.abs() / 50).clamp(0.0, 1.0),
                                  child: Icon(
                                    _dragOffset > 0
                                        ? Iconsax.arrow_left_2
                                        : Iconsax.arrow_right_2,
                                    color: categoryColor,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Close button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _dismissQuote,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Iconsax.close_circle,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(quote.category),
                                    color: categoryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Daily ${quote.categoryLabel}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: categoryColor,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Iconsax.arrow_left_2,
                                            size: 12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Swipe for more tips',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  fontSize: 11,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Iconsax.arrow_right_2,
                                            size: 12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 40), // Space for close button
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Quote text
                            Text(
                              quote.text,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.6,
                                    fontSize: 14,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }
}
