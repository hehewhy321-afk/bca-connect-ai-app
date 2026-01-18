import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

class ColorMatchGameScreen extends StatefulWidget {
  const ColorMatchGameScreen({super.key});

  @override
  State<ColorMatchGameScreen> createState() => _ColorMatchGameScreenState();
}

class _ColorMatchGameScreenState extends State<ColorMatchGameScreen> with TickerProviderStateMixin {
  final _repository = GameRepository();
  final _random = Random();
  
  // Game state
  bool _isPlaying = false;
  int _score = 0;
  int _lives = 3;
  int _timeLeft = 60;
  int _combo = 0;
  Timer? _gameTimer;
  
  // Current question
  String _currentWord = '';
  Color _currentColor = Colors.red;
  List<ColorOption> _options = [];
  
  // Animation
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  
  // Colors and words
  final List<ColorData> _colors = [
    ColorData('RED', Colors.red),
    ColorData('BLUE', Colors.blue),
    ColorData('GREEN', Colors.green),
    ColorData('YELLOW', Colors.yellow),
    ColorData('PURPLE', Colors.purple),
    ColorData('ORANGE', Colors.orange),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _lives = 3;
      _timeLeft = 60;
      _combo = 0;
    });
    
    _generateQuestion();
    _startTimer();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endGame();
        }
      });
    });
  }

  void _generateQuestion() {
    final wordData = _colors[_random.nextInt(_colors.length)];
    final colorData = _colors[_random.nextInt(_colors.length)];
    
    setState(() {
      _currentWord = wordData.name;
      _currentColor = colorData.color;
      _options = _colors.map((c) => ColorOption(c.name, c.color)).toList()..shuffle();
    });
  }

  void _checkAnswer(Color selectedColor) {
    HapticFeedback.lightImpact();
    
    if (selectedColor == _currentColor) {
      // Correct!
      setState(() {
        _combo++;
        final points = 10 * (_combo > 5 ? 2 : 1); // 2x multiplier after 5 combo
        _score += points;
      });
      _generateQuestion();
    } else {
      // Wrong!
      _shakeController.forward().then((_) => _shakeController.reset());
      HapticFeedback.heavyImpact();
      setState(() {
        _lives--;
        _combo = 0;
        if (_lives <= 0) {
          _endGame();
        } else {
          _generateQuestion();
        }
      });
    }
  }

  void _endGame() {
    _gameTimer?.cancel();
    setState(() => _isPlaying = false);
    
    // Save score
    _repository.saveScore(GameScore(
      gameId: 'color_match',
      score: _score,
      timestamp: DateTime.now(),
      accuracy: ((_score / 10) * 100 / 60).round(),
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
            Text('🎮'),
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
                color: ModernTheme.primaryOrange,
              ),
            ),
            const Text('POINTS'),
            const SizedBox(height: 16),
            _buildStatRow('⏱️', 'Time', '${60 - _timeLeft}s'),
            _buildStatRow('🎯', 'Accuracy', '${(_score / 10).round()}/60'),
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
              backgroundColor: ModernTheme.primaryOrange,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEC4899).withValues(alpha: 0.1),
              const Color(0xFFF59E0B).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildGameHeader(),
              const SizedBox(height: 20),
              _buildQuestionCard(),
              const Spacer(),
              _buildOptionsGrid(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Match Madness'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEC4899).withValues(alpha: 0.1),
              const Color(0xFFF59E0B).withValues(alpha: 0.1),
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
                  '🎨',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Color Match Madness',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap the COLOR, not the word!',
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
                      _buildInstruction('1️⃣', 'A color word appears (e.g., "RED")'),
                      _buildInstruction('2️⃣', 'But it\'s written in a different color'),
                      _buildInstruction('3️⃣', 'Tap the actual COLOR, not the word!'),
                      _buildInstruction('⏱️', '60 seconds to score as much as you can'),
                      _buildInstruction('❤️', 'You have 3 lives'),
                      _buildInstruction('🔥', '5+ combo = 2x points!'),
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
                      backgroundColor: ModernTheme.primaryOrange,
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
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
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
          const Spacer(),
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _timeLeft <= 10 ? Colors.red : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.timer_1,
                  color: _timeLeft <= 10 ? Colors.white : null,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$_timeLeft',
                  style: TextStyle(
                    color: _timeLeft <= 10 ? Colors.white : null,
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

  Widget _buildQuestionCard() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = sin(_shakeController.value * pi * 4) * 10;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _currentColor.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            if (_combo >= 5)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.red],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${_combo}x COMBO!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            if (_combo >= 5) const SizedBox(height: 16),
            Text(
              _currentWord,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: _currentColor,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap the COLOR!',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: _options.length,
        itemBuilder: (context, index) {
          final option = _options[index];
          return InkWell(
            onTap: () => _checkAnswer(option.color),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: option.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: option.color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  option.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ColorData {
  final String name;
  final Color color;

  ColorData(this.name, this.color);
}

class ColorOption {
  final String name;
  final Color color;

  ColorOption(this.name, this.color);
}
