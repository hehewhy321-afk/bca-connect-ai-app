import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

class BalloonPopGameScreen extends StatefulWidget {
  const BalloonPopGameScreen({super.key});

  @override
  State<BalloonPopGameScreen> createState() => _BalloonPopGameScreenState();
}

class _BalloonPopGameScreenState extends State<BalloonPopGameScreen> {
  final _repository = GameRepository();
  
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _bestScore = 0;
  int _missed = 0;
  final int _maxMissed = 10;
  
  // Balloons
  final List<Balloon> _balloons = [];
  Timer? _gameTimer;
  Timer? _spawnTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final stats = await _repository.getStats('balloon_pop');
    setState(() {
      _bestScore = stats.highScore;
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _missed = 0;
      _balloons.clear();
    });
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updateBalloons();
    });
    
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      _spawnBalloon();
    });
  }

  void _spawnBalloon() {
    if (!_isPlaying || _balloons.length >= 15) return;
    
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];
    
    setState(() {
      _balloons.add(Balloon(
        id: DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000),
        x: _random.nextDouble() * 0.8 - 0.4,
        y: 1.2,
        color: colors[_random.nextInt(colors.length)],
        speed: 0.01 + _random.nextDouble() * 0.01,
        size: 60.0 + _random.nextDouble() * 20,
      ));
    });
  }

  void _updateBalloons() {
    if (!_isPlaying) return;
    
    setState(() {
      for (var balloon in _balloons) {
        balloon.y -= balloon.speed;
      }
      
      // Remove balloons that escaped
      final escapedCount = _balloons.where((b) => b.y < -1.2).length;
      if (escapedCount > 0) {
        _missed += escapedCount;
        HapticFeedback.lightImpact();
      }
      
      _balloons.removeWhere((b) => b.y < -1.2);
      
      if (_missed >= _maxMissed) {
        _endGame();
      }
    });
  }

  void _popBalloon(Balloon balloon) {
    if (!_isPlaying) return;
    
    setState(() {
      _balloons.remove(balloon);
      _score += 10;
    });
    
    HapticFeedback.mediumImpact();
  }

  void _endGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
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
      gameId: 'balloon_pop',
      score: _score,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (details) {
          if (!_isPlaying) return;
          
          for (var balloon in _balloons) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            
            final balloonX = screenWidth / 2 + (balloon.x * screenWidth / 2);
            final balloonY = screenHeight / 2 + (balloon.y * screenHeight / 2);
            
            final dx = details.localPosition.dx - balloonX;
            final dy = details.localPosition.dy - balloonY;
            final distance = sqrt(dx * dx + dy * dy);
            
            if (distance < balloon.size / 2) {
              _popBalloon(balloon);
              break;
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF56CCF2),
                const Color(0xFF2F80ED),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Clouds
                _buildClouds(),
                
                // Header
                _buildHeader(),
                
                // Stats
                if (_isPlaying) _buildStats(),
                
                // Balloons
                ..._balloons.map((balloon) => _buildBalloon(balloon)),
                
                // Start screen
                if (!_isPlaying && !_isGameOver) _buildStartScreen(),
                
                // Game over
                if (_isGameOver) _buildGameOverDialog(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClouds() {
    return Stack(
      children: [
        Positioned(
          top: 100,
          left: 30,
          child: _buildCloud(),
        ),
        Positioned(
          top: 200,
          right: 50,
          child: _buildCloud(),
        ),
        Positioned(
          top: 350,
          left: 100,
          child: _buildCloud(),
        ),
      ],
    );
  }

  Widget _buildCloud() {
    return Container(
      width: 100,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(25),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 16,
      left: 16,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Iconsax.arrow_left, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Column(
        children: [
          const Text(
            '🎪 Balloon Pop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('🎯', '$_score'),
                _buildStatItem('❌', '$_missed/$_maxMissed'),
              ],
            ),
          ),
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

  Widget _buildBalloon(Balloon balloon) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),
      left: MediaQuery.of(context).size.width / 2 + (balloon.x * MediaQuery.of(context).size.width / 2) - balloon.size / 2,
      top: MediaQuery.of(context).size.height / 2 + (balloon.y * MediaQuery.of(context).size.height / 2) - balloon.size,
      child: Column(
        children: [
          Container(
            width: balloon.size,
            height: balloon.size * 1.2,
            decoration: BoxDecoration(
              color: balloon.color,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(balloon.size / 2),
                bottom: Radius.circular(balloon.size / 3),
              ),
              boxShadow: [
                BoxShadow(
                  color: balloon.color.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: balloon.size * 0.3,
                height: balloon.size * 0.4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(balloon.size * 0.2),
                ),
              ),
            ),
          ),
          Container(
            width: 2,
            height: 30,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
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
              '🎈',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 20),
            const Text(
              'Balloon Pop',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pop balloons before they escape!',
              textAlign: TextAlign.center,
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
                '💔',
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

class Balloon {
  final int id;
  final double x;
  double y;
  final Color color;
  final double speed;
  final double size;

  Balloon({
    required this.id,
    required this.x,
    required this.y,
    required this.color,
    required this.speed,
    required this.size,
  });
}
