import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

enum SwipeDirection { up, down, left, right }
enum ArrowType { normal, opposite, any }

class SwipeManiaGameScreen extends StatefulWidget {
  const SwipeManiaGameScreen({super.key});

  @override
  State<SwipeManiaGameScreen> createState() => _SwipeManiaGameScreenState();
}

class _SwipeManiaGameScreenState extends State<SwipeManiaGameScreen> with TickerProviderStateMixin {
  final _repository = GameRepository();
  final _random = Random();
  
  // Game state
  bool _isPlaying = false;
  int _score = 0;
  int _lives = 3;
  int _combo = 0;
  int _level = 1;
  
  // Current arrow
  SwipeDirection _currentDirection = SwipeDirection.up;
  ArrowType _currentType = ArrowType.opposite;
  Color _arrowColor = Colors.blue;
  
  // Animation
  late AnimationController _arrowController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  
  // Timing
  Timer? _nextArrowTimer;
  int _arrowDelay = 2000; // milliseconds

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nextArrowTimer?.cancel();
    _arrowController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _lives = 3;
      _combo = 0;
      _level = 1;
      _arrowDelay = 2000;
    });
    
    _showNextArrow();
  }

  void _showNextArrow() {
    if (!_isPlaying) return;
    
    setState(() {
      _currentDirection = SwipeDirection.values[_random.nextInt(4)];
      
      // Determine arrow type based on level
      if (_level < 3) {
        _currentType = ArrowType.opposite;
        _arrowColor = Colors.blue;
      } else if (_level < 6) {
        _currentType = _random.nextBool() ? ArrowType.opposite : ArrowType.normal;
        _arrowColor = _currentType == ArrowType.normal ? Colors.red : Colors.blue;
      } else {
        final rand = _random.nextInt(10);
        if (rand < 6) {
          _currentType = ArrowType.opposite;
          _arrowColor = Colors.blue;
        } else if (rand < 9) {
          _currentType = ArrowType.normal;
          _arrowColor = Colors.red;
        } else {
          _currentType = ArrowType.any;
          _arrowColor = Colors.green;
        }
      }
    });
    
    _arrowController.forward().then((_) => _arrowController.reset());
    
    // Schedule next arrow
    _nextArrowTimer?.cancel();
    _nextArrowTimer = Timer(Duration(milliseconds: _arrowDelay), () {
      if (_isPlaying) {
        _loseLife();
        _showNextArrow();
      }
    });
  }

  void _handleSwipe(SwipeDirection swipedDirection) {
    _nextArrowTimer?.cancel();
    
    bool isCorrect = false;
    
    switch (_currentType) {
      case ArrowType.opposite:
        isCorrect = _getOppositeDirection(_currentDirection) == swipedDirection;
        break;
      case ArrowType.normal:
        isCorrect = _currentDirection == swipedDirection;
        break;
      case ArrowType.any:
        isCorrect = true;
        break;
    }
    
    if (isCorrect) {
      HapticFeedback.lightImpact();
      setState(() {
        _combo++;
        final points = 10 + (_combo ~/ 5) * 5; // Bonus for combo
        _score += points;
        
        // Level up every 10 points
        if (_score ~/ 100 > _level - 1) {
          _level++;
          _arrowDelay = max(800, _arrowDelay - 150); // Faster arrows
        }
      });
      _showNextArrow();
    } else {
      _loseLife();
      _showNextArrow();
    }
  }

  void _loseLife() {
    HapticFeedback.heavyImpact();
    _shakeController.forward().then((_) => _shakeController.reset());
    
    setState(() {
      _lives--;
      _combo = 0;
      if (_lives <= 0) {
        _endGame();
      }
    });
  }

  SwipeDirection _getOppositeDirection(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.up:
        return SwipeDirection.down;
      case SwipeDirection.down:
        return SwipeDirection.up;
      case SwipeDirection.left:
        return SwipeDirection.right;
      case SwipeDirection.right:
        return SwipeDirection.left;
    }
  }

  void _endGame() {
    _nextArrowTimer?.cancel();
    setState(() => _isPlaying = false);
    
    _repository.saveScore(GameScore(
      gameId: 'swipe_mania',
      score: _score,
      timestamp: DateTime.now(),
    ));
    
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('👆'),
            SizedBox(width: 8),
            Text('Game Over!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_score',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
            const Text('POINTS'),
            const SizedBox(height: 16),
            _buildStatRow('🎯', 'Level Reached', '$_level'),
            _buildStatRow('🔥', 'Best Combo', '$_combo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPlaying) {
      return _buildStartScreen();
    }
    
    return Scaffold(
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _handleSwipe(SwipeDirection.up);
          } else if (details.primaryVelocity! > 0) {
            _handleSwipe(SwipeDirection.down);
          }
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _handleSwipe(SwipeDirection.left);
          } else if (details.primaryVelocity! > 0) {
            _handleSwipe(SwipeDirection.right);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6366F1).withValues(alpha: 0.1),
                const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildGameHeader(),
                const Spacer(),
                _buildArrowDisplay(),
                const Spacer(),
                _buildInstructions(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swipe Mania'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.1),
              const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '👆',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Swipe Mania',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Swipe the opposite direction!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to Play:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInstruction('🔵', 'BLUE arrow = Swipe OPPOSITE direction'),
                      _buildInstruction('🔴', 'RED arrow = Swipe SAME direction'),
                      _buildInstruction('🟢', 'GREEN arrow = Swipe ANY direction'),
                      _buildInstruction('⚡', 'React fast before time runs out!'),
                      _buildInstruction('❤️', 'You have 3 lives'),
                      _buildInstruction('📈', 'Game gets faster as you level up!'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.play_circle),
                        SizedBox(width: 12),
                        Text(
                          'START GAME',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Lives
          Row(
            children: List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                index < _lives ? Iconsax.heart5 : Iconsax.heart,
                color: index < _lives ? Colors.red : Colors.grey,
                size: 24,
              ),
            )),
          ),
          const Spacer(),
          // Level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.level, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lv $_level',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.cup, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$_score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowDisplay() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = sin(_shakeController.value * pi * 4) * 10;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _arrowController, curve: Curves.elasticOut),
        ),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _arrowColor.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              _getArrowIcon(_currentDirection),
              size: 100,
              color: _arrowColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    String instruction = '';
    switch (_currentType) {
      case ArrowType.opposite:
        instruction = 'Swipe OPPOSITE direction!';
        break;
      case ArrowType.normal:
        instruction = 'Swipe SAME direction!';
        break;
      case ArrowType.any:
        instruction = 'Swipe ANY direction!';
        break;
    }
    
    return Column(
      children: [
        if (_combo >= 5)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.red],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  '${_combo}x COMBO!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          instruction,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getArrowIcon(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.up:
        return Icons.arrow_upward_rounded;
      case SwipeDirection.down:
        return Icons.arrow_downward_rounded;
      case SwipeDirection.left:
        return Icons.arrow_back_rounded;
      case SwipeDirection.right:
        return Icons.arrow_forward_rounded;
    }
  }
}
