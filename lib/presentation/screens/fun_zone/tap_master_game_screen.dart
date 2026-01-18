import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

enum GameState { waiting, ready, tooEarly, result }

class TapMasterGameScreen extends StatefulWidget {
  const TapMasterGameScreen({super.key});

  @override
  State<TapMasterGameScreen> createState() => _TapMasterGameScreenState();
}

class _TapMasterGameScreenState extends State<TapMasterGameScreen> with TickerProviderStateMixin {
  final _repository = GameRepository();
  final _random = Random();
  
  // Game state
  bool _isPlaying = false;
  GameState _state = GameState.waiting;
  int _round = 0;
  final int _totalRounds = 5;
  List<int> _reactionTimes = [];
  
  // Timing
  DateTime? _greenTime;
  Timer? _delayTimer;
  
  // Animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _round = 0;
      _reactionTimes = [];
    });
    
    _startRound();
  }

  void _startRound() {
    setState(() {
      _round++;
      _state = GameState.waiting;
    });
    
    // Random delay between 1-4 seconds
    final delay = 1000 + _random.nextInt(3000);
    
    _delayTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        setState(() {
          _state = GameState.ready;
          _greenTime = DateTime.now();
        });
      }
    });
  }

  void _handleTap() {
    if (_state == GameState.waiting) {
      // Tapped too early!
      _delayTimer?.cancel();
      HapticFeedback.heavyImpact();
      setState(() => _state = GameState.tooEarly);
      
      Future.delayed(const Duration(seconds: 2), () {
        if (_round < _totalRounds) {
          _startRound();
        } else {
          _endGame();
        }
      });
    } else if (_state == GameState.ready) {
      // Perfect! Calculate reaction time
      final reactionTime = DateTime.now().difference(_greenTime!).inMilliseconds;
      HapticFeedback.lightImpact();
      
      setState(() {
        _reactionTimes.add(reactionTime);
        _state = GameState.result;
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        if (_round < _totalRounds) {
          _startRound();
        } else {
          _endGame();
        }
      });
    }
  }

  void _endGame() {
    setState(() => _isPlaying = false);
    
    if (_reactionTimes.isNotEmpty) {
      final avgTime = _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;
      final bestTime = _reactionTimes.reduce(min);
      
      // Score based on average reaction time (lower is better)
      final score = max(0, 1000 - avgTime);
      
      _repository.saveScore(GameScore(
        gameId: 'tap_master',
        score: score,
        timestamp: DateTime.now(),
        timeMs: bestTime,
      ));
    }
    
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    if (_reactionTimes.isEmpty) {
      Navigator.pop(context);
      return;
    }
    
    final avgTime = _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;
    final bestTime = _reactionTimes.reduce(min);
    final worstTime = _reactionTimes.reduce(max);
    
    String rating = '';
    if (avgTime < 200) {
      rating = '🚀 Lightning Fast!';
    } else if (avgTime < 300) {
      rating = '⚡ Super Quick!';
    } else if (avgTime < 400) {
      rating = '👍 Good Reflexes!';
    } else if (avgTime < 500) {
      rating = '😊 Not Bad!';
    } else {
      rating = '🐌 Keep Practicing!';
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('⚡'),
            SizedBox(width: 8),
            Text('Results'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${avgTime}ms',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
            const Text('AVERAGE TIME'),
            const SizedBox(height: 8),
            Text(
              rating,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('🏆', 'Best', '${bestTime}ms'),
            _buildStatRow('📊', 'Worst', '${worstTime}ms'),
            _buildStatRow('✅', 'Completed', '${_reactionTimes.length}/$_totalRounds'),
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
              backgroundColor: const Color(0xFF10B981),
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
        onTap: _handleTap,
        child: Container(
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildGameHeader(),
                Expanded(
                  child: Center(
                    child: _buildGameContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_state) {
      case GameState.waiting:
        return Colors.red.shade400;
      case GameState.ready:
        return Colors.green.shade400;
      case GameState.tooEarly:
        return Colors.orange.shade400;
      case GameState.result:
        return Colors.blue.shade400;
    }
  }

  Widget _buildStartScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap Master'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF10B981).withValues(alpha: 0.1),
              const Color(0xFF06B6D4).withValues(alpha: 0.1),
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
                  '⚡',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tap Master',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Test your reaction speed!',
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
                      _buildInstruction('🔴', 'Wait for RED screen'),
                      _buildInstruction('🟢', 'When it turns GREEN, TAP immediately!'),
                      _buildInstruction('⚠️', 'Tap too early = penalty'),
                      _buildInstruction('📊', '5 rounds to test your reflexes'),
                      _buildInstruction('🏆', 'Lower time = better score!'),
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
                      backgroundColor: const Color(0xFF10B981),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Round $_round/$_totalRounds',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_reactionTimes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Last: ${_reactionTimes.last}ms',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    switch (_state) {
      case GameState.waiting:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'WAIT...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Get ready to tap!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        );
      
      case GameState.ready:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'TAP NOW!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Tap anywhere!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        );
      
      case GameState.tooEarly:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_rounded, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'TOO EARLY!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Wait for green!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        );
      
      case GameState.result:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              '${_reactionTimes.last}ms',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getRating(_reactionTimes.last),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        );
    }
  }

  String _getRating(int ms) {
    if (ms < 200) return '🚀 Lightning Fast!';
    if (ms < 300) return '⚡ Super Quick!';
    if (ms < 400) return '👍 Good!';
    if (ms < 500) return '😊 Not Bad!';
    return '🐌 Keep Trying!';
  }
}
