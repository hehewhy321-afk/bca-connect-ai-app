import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

class BrickBreakerGameScreen extends StatefulWidget {
  const BrickBreakerGameScreen({super.key});

  @override
  State<BrickBreakerGameScreen> createState() => _BrickBreakerGameScreenState();
}

class _BrickBreakerGameScreenState extends State<BrickBreakerGameScreen> {
  final _repository = GameRepository();
  
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _bestScore = 0;
  int _lives = 3;
  
  // Ball
  double _ballX = 0.0;
  double _ballY = 0.0;
  double _ballVelocityX = 0.02;
  double _ballVelocityY = -0.02;
  
  // Paddle
  double _paddleX = 0.0;
  final double _paddleWidth = 0.3;
  
  // Bricks
  final List<Brick> _bricks = [];
  final int _brickRows = 5;
  final int _brickCols = 6;
  
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
    final stats = await _repository.getStats('brick_breaker');
    setState(() {
      _bestScore = stats.highScore;
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _lives = 3;
      _ballX = 0.0;
      _ballY = 0.5;
      _ballVelocityX = 0.02;
      _ballVelocityY = -0.02;
      _paddleX = 0.0;
      _initializeBricks();
    });
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
  }

  void _initializeBricks() {
    _bricks.clear();
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
    ];
    
    for (int i = 0; i < _brickRows; i++) {
      for (int j = 0; j < _brickCols; j++) {
        _bricks.add(Brick(
          x: -0.9 + (j * 0.32),
          y: -0.9 + (i * 0.12),
          width: 0.28,
          height: 0.08,
          color: colors[i],
          isDestroyed: false,
        ));
      }
    }
  }

  void _updateGame() {
    if (!_isPlaying || _isGameOver) return;
    
    setState(() {
      // Update ball position
      _ballX += _ballVelocityX;
      _ballY += _ballVelocityY;
      
      // Wall collision
      if (_ballX <= -1.0 || _ballX >= 1.0) {
        _ballVelocityX = -_ballVelocityX;
        HapticFeedback.lightImpact();
      }
      
      if (_ballY <= -1.0) {
        _ballVelocityY = -_ballVelocityY;
        HapticFeedback.lightImpact();
      }
      
      // Bottom boundary (lose life)
      if (_ballY >= 1.0) {
        _lives--;
        if (_lives <= 0) {
          _endGame();
        } else {
          _ballX = 0.0;
          _ballY = 0.5;
          _ballVelocityX = 0.02;
          _ballVelocityY = -0.02;
          HapticFeedback.heavyImpact();
        }
        return;
      }
      
      // Paddle collision
      if (_ballY >= 0.8 && _ballY <= 0.85 &&
          _ballX >= _paddleX - _paddleWidth / 2 &&
          _ballX <= _paddleX + _paddleWidth / 2) {
        _ballVelocityY = -_ballVelocityY.abs();
        
        // Add spin based on where ball hits paddle
        final hitPosition = (_ballX - _paddleX) / (_paddleWidth / 2);
        _ballVelocityX = hitPosition * 0.03;
        
        HapticFeedback.mediumImpact();
      }
      
      // Brick collision
      for (var brick in _bricks) {
        if (!brick.isDestroyed && _checkBrickCollision(brick)) {
          brick.isDestroyed = true;
          _score += 10;
          _ballVelocityY = -_ballVelocityY;
          HapticFeedback.mediumImpact();
          
          // Check win condition
          if (_bricks.every((b) => b.isDestroyed)) {
            _endGame(won: true);
          }
          break;
        }
      }
    });
  }

  bool _checkBrickCollision(Brick brick) {
    return _ballX >= brick.x - brick.width / 2 &&
           _ballX <= brick.x + brick.width / 2 &&
           _ballY >= brick.y - brick.height / 2 &&
           _ballY <= brick.y + brick.height / 2;
  }

  void _movePaddle(double delta) {
    setState(() {
      _paddleX += delta;
      _paddleX = _paddleX.clamp(-0.7, 0.7);
    });
  }

  void _endGame({bool won = false}) {
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
      gameId: 'brick_breaker',
      score: _score,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (_isPlaying) {
            _movePaddle(details.delta.dx / MediaQuery.of(context).size.width * 2);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A2980),
                const Color(0xFF26D0CE),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (_isPlaying) _buildStats(),
                Expanded(child: _buildGameBoard()),
                if (_isGameOver) _buildGameOverDialog(),
              ],
            ),
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
            '🧱 Brick Breaker',
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

  Widget _buildStats() {
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
          _buildStatItem('❤️', 'x$_lives'),
          _buildStatItem('🎯', '$_score'),
          _buildStatItem('🏆', '$_bestScore'),
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
                '🧱',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 20),
              const Text(
                'Brick Breaker',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Break all the bricks!',
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
    
    return Stack(
      children: [
        // Bricks
        ..._bricks.where((b) => !b.isDestroyed).map((brick) {
          return Align(
            alignment: Alignment(brick.x, brick.y),
            child: Container(
              width: MediaQuery.of(context).size.width * brick.width / 2,
              height: 30,
              decoration: BoxDecoration(
                color: brick.color,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          );
        }),
        
        // Ball
        Align(
          alignment: Alignment(_ballX, _ballY),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        
        // Paddle
        Align(
          alignment: Alignment(_paddleX, 0.9),
          child: Container(
            width: MediaQuery.of(context).size.width * _paddleWidth / 2,
            height: 15,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ModernTheme.primaryOrange,
                  ModernTheme.primaryOrange.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: ModernTheme.primaryOrange.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverDialog() {
    final won = _bricks.every((b) => b.isDestroyed);
    
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
              Text(
                won ? '🎉' : '💔',
                style: const TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 16),
              Text(
                won ? 'You Won!' : 'Game Over!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: won ? Colors.green : Colors.red,
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

class Brick {
  double x;
  double y;
  double width;
  double height;
  Color color;
  bool isDestroyed;

  Brick({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    required this.isDestroyed,
  });
}
