import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({super.key});

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen> {
  final _repository = GameRepository();
  
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _bestScore = 0;
  
  // Snake
  List<Point<int>> _snake = [];
  String _direction = 'right';
  String _nextDirection = 'right';
  
  // Food
  Point<int>? _food;
  
  // Grid
  final int _gridSize = 20;
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final stats = await _repository.getStats('snake_game');
    setState(() {
      _bestScore = stats.highScore;
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _direction = 'right';
      _nextDirection = 'right';
      
      // Initialize snake in center
      _snake = [
        Point(_gridSize ~/ 2, _gridSize ~/ 2),
        Point(_gridSize ~/ 2 - 1, _gridSize ~/ 2),
        Point(_gridSize ~/ 2 - 2, _gridSize ~/ 2),
      ];
      
      _spawnFood();
    });
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _updateGame();
    });
  }

  void _updateGame() {
    if (!_isPlaying || _isGameOver) return;
    
    _direction = _nextDirection;
    
    // Calculate new head position
    final head = _snake.first;
    Point<int> newHead;
    
    switch (_direction) {
      case 'up':
        newHead = Point(head.x, head.y - 1);
        break;
      case 'down':
        newHead = Point(head.x, head.y + 1);
        break;
      case 'left':
        newHead = Point(head.x - 1, head.y);
        break;
      case 'right':
        newHead = Point(head.x + 1, head.y);
        break;
      default:
        newHead = head;
    }
    
    // Check wall collision
    if (newHead.x < 0 || newHead.x >= _gridSize || 
        newHead.y < 0 || newHead.y >= _gridSize) {
      _endGame();
      return;
    }
    
    // Check self collision
    if (_snake.contains(newHead)) {
      _endGame();
      return;
    }
    
    setState(() {
      _snake.insert(0, newHead);
      
      // Check food collision
      if (newHead == _food) {
        _score += 10;
        _spawnFood();
        HapticFeedback.mediumImpact();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _spawnFood() {
    final random = Random();
    Point<int> newFood;
    
    do {
      newFood = Point(
        random.nextInt(_gridSize),
        random.nextInt(_gridSize),
      );
    } while (_snake.contains(newFood));
    
    setState(() {
      _food = newFood;
    });
  }

  void _changeDirection(String newDirection) {
    // Prevent 180-degree turns
    if (_direction == 'up' && newDirection == 'down') return;
    if (_direction == 'down' && newDirection == 'up') return;
    if (_direction == 'left' && newDirection == 'right') return;
    if (_direction == 'right' && newDirection == 'left') return;
    
    setState(() {
      _nextDirection = newDirection;
    });
    
    HapticFeedback.lightImpact();
  }

  void _endGame() {
    _gameTimer?.cancel();
    setState(() {
      _isGameOver = true;
      _isPlaying = false;
    });
    
    HapticFeedback.heavyImpact();
    _saveScore();
  }

  Future<void> _saveScore() async {
    if (_score > _bestScore) {
      setState(() {
        _bestScore = _score;
      });
    }
    
    await _repository.saveScore(GameScore(
      gameId: 'snake_game',
      score: _score,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF11998E),
              const Color(0xFF38EF7D),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_isPlaying) _buildScore(),
              Expanded(child: _buildGameBoard()),
              if (_isPlaying) _buildControls(),
              if (_isGameOver) _buildGameOverDialog(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.arrow_left, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const Spacer(),
          const Text(
            '🐍 Snake Classic',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(width: 48),
        ],
      ),
    );
  }

  Widget _buildScore() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('🎯', 'Score: $_score'),
          _buildStatItem('🏆', 'Best: $_bestScore'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGameBoard() {
    if (!_isPlaying && !_isGameOver) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🐍',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 20),
              const Text(
                'Snake Classic',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Eat food, grow longer!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Best: $_bestScore points',
                style: const TextStyle(
                  fontSize: 14,
                  color: ModernTheme.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'START GAME',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridSize,
            ),
            itemCount: _gridSize * _gridSize,
            itemBuilder: (context, index) {
              final x = index % _gridSize;
              final y = index ~/ _gridSize;
              final point = Point(x, y);
              
              final isSnakeHead = _snake.isNotEmpty && point == _snake.first;
              final isSnakeBody = _snake.contains(point) && !isSnakeHead;
              final isFood = point == _food;
              
              return Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isSnakeHead
                      ? Colors.yellow
                      : isSnakeBody
                          ? Colors.green
                          : isFood
                              ? Colors.red
                              : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Up button
          IconButton(
            onPressed: () => _changeDirection('up'),
            icon: const Icon(Iconsax.arrow_up_2, size: 32),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 8),
          // Left, Down, Right buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _changeDirection('left'),
                icon: const Icon(Iconsax.arrow_left_2, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(width: 60),
              IconButton(
                onPressed: () => _changeDirection('down'),
                icon: const Icon(Iconsax.arrow_down_2, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(width: 60),
              IconButton(
                onPressed: () => _changeDirection('right'),
                icon: const Icon(Iconsax.arrow_right_3, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverDialog() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💀',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 16),
              const Text(
                'Game Over!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResultCard('Score', _score.toString(), '🎯'),
                  _buildResultCard('Best', _bestScore.toString(), '🏆'),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ModernTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Play Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, String value, String emoji) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ModernTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
