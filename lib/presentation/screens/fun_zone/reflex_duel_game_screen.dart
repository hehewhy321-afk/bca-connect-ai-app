import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

class ReflexDuelGameScreen extends StatefulWidget {
  const ReflexDuelGameScreen({super.key});

  @override
  State<ReflexDuelGameScreen> createState() => _ReflexDuelGameScreenState();
}

class _ReflexDuelGameScreenState extends State<ReflexDuelGameScreen> {
  final _repository = GameRepository();
  
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _bestScore = 0;
  int _round = 0;
  final int _maxRounds = 10;
  
  // Challenge state
  String _challengeType = '';
  String _instruction = '';
  bool _showChallenge = false;
  int _startTime = 0;
  int _reactionTime = 0;
  final Random _random = Random();
  
  // Challenge types
  final List<Map<String, dynamic>> _challenges = [
    {'type': 'tap_green', 'instruction': 'TAP WHEN GREEN!', 'color': Colors.green},
    {'type': 'tap_blue', 'instruction': 'TAP WHEN BLUE!', 'color': Colors.blue},
    {'type': 'tap_yellow', 'instruction': 'TAP WHEN YELLOW!', 'color': Colors.yellow},
    {'type': 'dont_tap_red', 'instruction': 'DON\'T TAP RED!', 'color': Colors.red},
  ];
  
  Color _currentColor = Colors.grey;
  Color _targetColor = Colors.green;
  bool _shouldTap = true;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  Future<void> _loadBestScore() async {
    final stats = await _repository.getStats('reflex_duel');
    setState(() {
      _bestScore = stats.highScore;
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _round = 0;
    });
    
    _nextRound();
  }

  void _nextRound() {
    if (_round >= _maxRounds) {
      _endGame();
      return;
    }
    
    setState(() {
      _round++;
      _showChallenge = false;
      _currentColor = Colors.grey;
    });
    
    // Select random challenge
    final challenge = _challenges[_random.nextInt(_challenges.length)];
    _challengeType = challenge['type'];
    _instruction = challenge['instruction'];
    _targetColor = challenge['color'];
    _shouldTap = !_challengeType.contains('dont');
    
    // Wait random time before showing challenge
    final waitTime = 1000 + _random.nextInt(2000);
    
    Future.delayed(Duration(milliseconds: waitTime), () {
      if (!_isPlaying) return;
      
      setState(() {
        _showChallenge = true;
        _currentColor = _targetColor;
        _startTime = DateTime.now().millisecondsSinceEpoch;
      });
      
      // Auto-fail if no response in 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (_showChallenge && _isPlaying) {
          _handleResponse(false);
        }
      });
    });
  }

  void _onTap() {
    if (!_isPlaying || !_showChallenge) return;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    _reactionTime = now - _startTime;
    
    final correct = _shouldTap;
    _handleResponse(correct);
  }

  void _handleResponse(bool correct) {
    if (!_showChallenge) return;
    
    setState(() {
      _showChallenge = false;
    });
    
    if (correct) {
      final points = max(0, 100 - (_reactionTime ~/ 10));
      setState(() {
        _score += points;
      });
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isPlaying) {
        _nextRound();
      }
    });
  }

  void _endGame() {
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
      gameId: 'reflex_duel',
      score: _score,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _showChallenge
                  ? [_currentColor, _currentColor.withValues(alpha: 0.7)]
                  : [
                      const Color(0xFF232526),
                      const Color(0xFF414345),
                    ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Header
                if (!_showChallenge) _buildHeader(),
                
                // Stats
                if (_isPlaying && !_showChallenge) _buildStats(),
                
                // Challenge
                if (_showChallenge) _buildChallenge(),
                
                // Waiting
                if (_isPlaying && !_showChallenge && !_isGameOver) _buildWaiting(),
                
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
            '⚔️ Reflex Duel',
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
                _buildStatItem('📊', '$_round/$_maxRounds'),
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

  Widget _buildChallenge() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _instruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 40),
          if (_shouldTap)
            const Text(
              'TAP NOW!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            const Text(
              'DON\'T TAP!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaiting() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _instruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Get Ready...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
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
              '⚔️',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 20),
            const Text(
              'Reflex Duel',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Test your reaction speed!\nTap when told, avoid when warned.',
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
                '🎉',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 16),
              const Text(
                'Complete!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
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
