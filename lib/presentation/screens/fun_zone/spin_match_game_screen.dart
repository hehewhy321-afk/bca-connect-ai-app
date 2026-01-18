import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

class SpinMatchGameScreen extends StatefulWidget {
  const SpinMatchGameScreen({super.key});

  @override
  State<SpinMatchGameScreen> createState() => _SpinMatchGameScreenState();
}

class _SpinMatchGameScreenState extends State<SpinMatchGameScreen> with TickerProviderStateMixin {
  final _repository = GameRepository();
  
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _bestScore = 0;
  int _timeLeft = 45;
  Timer? _timer;
  
  // Symbols
  final List<String> _symbols = ['🎮', '🎯', '🎨', '🎭', '🎪', '🎸'];
  String _targetSymbol = '🎮';
  List<SpinWheel> _wheels = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var wheel in _wheels) {
      wheel.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final stats = await _repository.getStats('spin_match');
    setState(() {
      _bestScore = stats.highScore;
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _timeLeft = 45;
      _initializeWheels();
      _setNewTarget();
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
      });
      
      if (_timeLeft <= 0) {
        _endGame();
      }
    });
  }

  void _initializeWheels() {
    for (var wheel in _wheels) {
      wheel.controller.dispose();
    }
    
    _wheels = List.generate(3, (index) {
      final controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );
      return SpinWheel(
        controller: controller,
        currentSymbol: _symbols[_random.nextInt(_symbols.length)],
      );
    });
  }

  void _setNewTarget() {
    setState(() {
      _targetSymbol = _symbols[_random.nextInt(_symbols.length)];
    });
  }

  void _spinWheel(int index) {
    if (!_isPlaying) return;
    
    final wheel = _wheels[index];
    wheel.controller.reset();
    wheel.controller.forward();
    
    HapticFeedback.lightImpact();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isPlaying) return;
      
      setState(() {
        wheel.currentSymbol = _symbols[_random.nextInt(_symbols.length)];
      });
      
      _checkMatch();
    });
  }

  void _checkMatch() {
    final allMatch = _wheels.every((w) => w.currentSymbol == _targetSymbol);
    
    if (allMatch) {
      setState(() {
        _score += 50;
        _timeLeft += 3;
      });
      HapticFeedback.heavyImpact();
      _setNewTarget();
    }
  }

  void _endGame() {
    _timer?.cancel();
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
      gameId: 'spin_match',
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
              const Color(0xFFDA22FF),
              const Color(0xFF9733EE),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_isPlaying) _buildStats(),
              Expanded(child: _buildGameContent()),
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
            '🔄 Spin Match',
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
          _buildStatItem('⏱️', '${_timeLeft}s'),
          _buildStatItem('🎯', '$_score'),
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

  Widget _buildGameContent() {
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
                '🔄',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 20),
              const Text(
                'Spin Match',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Match all symbols to the target!',
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
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Target
        Container(
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
            children: [
              const Text(
                'Match This:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _targetSymbol,
                style: const TextStyle(fontSize: 60),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Wheels
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildWheel(index),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWheel(int index) {
    final wheel = _wheels[index];
    
    return GestureDetector(
      onTap: () => _spinWheel(index),
      child: AnimatedBuilder(
        animation: wheel.controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: wheel.controller.value * 2 * pi * 3,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ModernTheme.primaryOrange,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  wheel.currentSymbol,
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
          );
        },
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
                '⏰',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 16),
              const Text(
                'Time\'s Up!',
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

class SpinWheel {
  final AnimationController controller;
  String currentSymbol;

  SpinWheel({
    required this.controller,
    required this.currentSymbol,
  });
}
