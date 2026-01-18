import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

class FlappyCodeGameScreen extends StatefulWidget {
  const FlappyCodeGameScreen({super.key});

  @override
  State<FlappyCodeGameScreen> createState() => _FlappyCodeGameScreenState();
}

class _FlappyCodeGameScreenState extends State<FlappyCodeGameScreen> {
  final _repository = GameRepository();
  
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _bestScore = 0;
  
  // Bird physics
  double _birdY = 0.0;
  double _velocity = 0.0;
  final double _gravity = 0.25; // Reduced gravity (was 0.5)
  final double _jumpPower = -6.0; // Reduced jump power (was -10.0)
  
  // Pipes
  final List<Map<String, double>> _pipes = [];
  final double _pipeGap = 0.8; // Increased gap (was 0.5)
  int _frameCount = 0;
  
  // Game loop
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
    final stats = await _repository.getStats('flappy_code');
    setState(() {
      _bestScore = stats.highScore;
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _birdY = 0.0;
      _velocity = 0.0;
      _frameCount = 0;
      _pipes.clear();
      _addPipe();
    });
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updateGame();
    });
  }

  void _updateGame() {
    if (!_isPlaying || _isGameOver) return;

    setState(() {
      _frameCount++;
      
      // Update bird physics
      _velocity += _gravity;
      _birdY += _velocity * 0.01;
      
      // Check boundaries
      if (_birdY > 1.0 || _birdY < -1.0) {
        _endGame();
        return;
      }
      
      // Update all pipes (slower speed)
      for (var pipe in _pipes) {
        pipe['x'] = pipe['x']! - 0.02; // Reduced speed (was 0.03)
      }
      
      // Add new pipe every 90 frames (more time between pipes)
      if (_frameCount % 90 == 0) {
        _addPipe();
      }
      
      // Remove off-screen pipes and add score
      _pipes.removeWhere((pipe) {
        if (pipe['x']! < -0.5 && pipe['scored'] == 0) {
          _score++;
          HapticFeedback.lightImpact();
          return true;
        }
        return false;
      });
      
      // Check collision with all pipes
      for (var pipe in _pipes) {
        final pipeX = pipe['x']!;
        final pipeHeight = pipe['height']!;
        
        // Bird is in pipe's x range
        if (pipeX < 0.2 && pipeX > -0.3) {
          // Check if bird hit pipe
          if (_birdY < pipeHeight - _pipeGap / 2 || 
              _birdY > pipeHeight + _pipeGap / 2) {
            _endGame();
            return;
          }
        }
      }
    });
  }

  void _addPipe() {
    final random = Random();
    final height = -0.3 + random.nextDouble() * 0.6; // -0.3 to 0.3 (more centered)
    _pipes.add({
      'x': 1.5,
      'height': height,
      'scored': 0,
    });
  }

  void _jump() {
    if (!_isPlaying) {
      _startGame();
      return;
    }
    
    if (_isGameOver) return;
    
    setState(() {
      _velocity = _jumpPower;
    });
    HapticFeedback.mediumImpact();
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
      gameId: 'flappy_code',
      score: _score,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _jump,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF87CEEB),
                const Color(0xFF87CEEB).withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Clouds decoration
              Positioned(
                top: 100,
                left: 50,
                child: _buildCloud(),
              ),
              Positioned(
                top: 200,
                right: 80,
                child: _buildCloud(),
              ),
              Positioned(
                top: 350,
                left: 150,
                child: _buildCloud(),
              ),
              
              // Pipes
              ..._pipes.map((pipe) => _buildPipe(pipe)),
              
              // Bird
              _buildBird(),
              
              // Ground
              _buildGround(),
              
              // UI Overlay
              _buildUI(),
              
              // Game Over Dialog
              if (_isGameOver) _buildGameOverDialog(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloud() {
    return Container(
      width: 80,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildBird() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 0),
      alignment: Alignment(0, _birdY),
      child: Transform.rotate(
        angle: _velocity * 0.03,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: ModernTheme.primaryOrange,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🐦',
              style: TextStyle(fontSize: 30),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPipe(Map<String, double> pipe) {
    final pipeX = pipe['x']!;
    final pipeHeight = pipe['height']!;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate pipe heights
    final topPipeHeight = screenHeight * 0.5 * (1 - (pipeHeight + _pipeGap / 2));
    final bottomPipeHeight = screenHeight * 0.5 * (1 + (pipeHeight - _pipeGap / 2));
    
    return Stack(
      children: [
        // Top pipe
        AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          alignment: Alignment(pipeX, -1),
          child: Container(
            width: 80,
            height: topPipeHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50),
                  const Color(0xFF66BB6A),
                ],
              ),
              border: Border.all(color: const Color(0xFF2E7D32), width: 3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
        ),
        // Bottom pipe
        AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          alignment: Alignment(pipeX, 1),
          child: Container(
            width: 80,
            height: bottomPipeHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF66BB6A),
                  const Color(0xFF4CAF50),
                ],
              ),
              border: Border.all(color: const Color(0xFF2E7D32), width: 3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGround() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8B4513),
              const Color(0xFF654321),
            ],
          ),
          border: Border(
            top: BorderSide(color: const Color(0xFF654321), width: 3),
          ),
        ),
        child: Row(
          children: List.generate(
            20,
            (index) => Expanded(
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF654321).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '🏆',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_bestScore',
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
          ),
          
          // Score
          if (_isPlaying)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                '$_score',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.primaryOrange,
                ),
              ),
            ),
          
          const Spacer(),
          
          // Start instruction
          if (!_isPlaying && !_isGameOver)
            Container(
              margin: const EdgeInsets.only(bottom: 100),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🐦',
                    style: TextStyle(fontSize: 60),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Flappy Code',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ModernTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap anywhere to fly!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      'TAP TO START',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💥',
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
                  _buildStatCard('Score', _score.toString(), '🎯'),
                  _buildStatCard('Best', _bestScore.toString(), '🏆'),
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

  Widget _buildStatCard(String label, String value, String emoji) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 30),
          ),
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
