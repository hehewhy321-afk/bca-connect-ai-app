import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

class MemoryMatchGameScreen extends StatefulWidget {
  const MemoryMatchGameScreen({super.key});

  @override
  State<MemoryMatchGameScreen> createState() => _MemoryMatchGameScreenState();
}

class _MemoryMatchGameScreenState extends State<MemoryMatchGameScreen> {
  final _repository = GameRepository();
  
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _moves = 0;
  int _matches = 0;
  int _bestScore = 999;
  int _timeElapsed = 0;
  Timer? _timer;
  
  // Cards
  final List<String> _emojis = ['🎮', '🎯', '🎨', '🎭', '🎪', '🎸', '🎺', '🎻'];
  List<CardItem> _cards = [];
  final List<int> _flippedIndices = [];
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    _initializeCards();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final stats = await _repository.getStats('memory_match');
    setState(() {
      _bestScore = stats.highScore == 0 ? 999 : stats.highScore;
    });
  }

  void _initializeCards() {
    final allEmojis = [..._emojis, ..._emojis];
    allEmojis.shuffle(Random());
    
    _cards = allEmojis.asMap().entries.map((entry) {
      return CardItem(
        id: entry.key,
        emoji: entry.value,
        isFlipped: false,
        isMatched: false,
      );
    }).toList();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _moves = 0;
      _matches = 0;
      _timeElapsed = 0;
      _flippedIndices.clear();
      _initializeCards();
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeElapsed++;
      });
    });
  }

  void _onCardTap(int index) {
    if (!_isPlaying || _isChecking || _cards[index].isFlipped || _cards[index].isMatched) {
      return;
    }
    
    setState(() {
      _cards[index].isFlipped = true;
      _flippedIndices.add(index);
    });
    
    HapticFeedback.lightImpact();
    
    if (_flippedIndices.length == 2) {
      _isChecking = true;
      _moves++;
      
      Future.delayed(const Duration(milliseconds: 800), () {
        _checkMatch();
      });
    }
  }

  void _checkMatch() {
    final first = _flippedIndices[0];
    final second = _flippedIndices[1];
    
    if (_cards[first].emoji == _cards[second].emoji) {
      // Match found
      setState(() {
        _cards[first].isMatched = true;
        _cards[second].isMatched = true;
        _matches++;
      });
      
      HapticFeedback.mediumImpact();
      
      if (_matches == _emojis.length) {
        _endGame();
      }
    } else {
      // No match
      setState(() {
        _cards[first].isFlipped = false;
        _cards[second].isFlipped = false;
      });
      
      HapticFeedback.lightImpact();
    }
    
    setState(() {
      _flippedIndices.clear();
      _isChecking = false;
    });
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
    if (_moves < _bestScore) {
      setState(() {
        _bestScore = _moves;
      });
    }
    
    await _repository.saveScore(GameScore(
      gameId: 'memory_match',
      score: _moves,
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
              const Color(0xFF667EEA),
              const Color(0xFF764BA2),
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
            '🧠 Memory Match',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (!_isPlaying)
            IconButton(
              onPressed: _startGame,
              icon: const Icon(Iconsax.play, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: ModernTheme.primaryOrange,
              ),
            )
          else
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
          _buildStatItem('⏱️', '${_timeElapsed}s'),
          _buildStatItem('🎯', '$_moves moves'),
          _buildStatItem('✅', '$_matches/${_emojis.length}'),
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
                '🧠',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 20),
              const Text(
                'Memory Match',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Find all matching pairs!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Best: $_bestScore moves',
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
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          return _buildCard(_cards[index], index);
        },
      ),
    );
  }

  Widget _buildCard(CardItem card, int index) {
    final isRevealed = card.isFlipped || card.isMatched;
    
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isMatched 
              ? Colors.green.withValues(alpha: 0.3)
              : isRevealed 
                  ? Colors.white 
                  : ModernTheme.primaryOrange,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            isRevealed ? card.emoji : '?',
            style: TextStyle(
              fontSize: 40,
              color: isRevealed ? Colors.black : Colors.white,
            ),
          ),
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
                'Completed!',
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
                  _buildResultCard('Moves', _moves.toString(), '🎯'),
                  _buildResultCard('Time', '${_timeElapsed}s', '⏱️'),
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

class CardItem {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  CardItem({
    required this.id,
    required this.emoji,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
