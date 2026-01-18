import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game_score.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  final _repository = GameRepository();
  
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _bestScore = 0;
  
  // Grid
  List<List<int>> _grid = [];
  final int _gridSize = 4;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    _initializeGrid();
  }

  Future<void> _loadBestScore() async {
    final stats = await _repository.getStats('game_2048');
    setState(() {
      _bestScore = stats.highScore;
    });
  }

  void _initializeGrid() {
    _grid = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _initializeGrid();
      _addRandomTile();
      _addRandomTile();
    });
  }

  void _addRandomTile() {
    final emptyCells = <Point<int>>[];
    
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_grid[i][j] == 0) {
          emptyCells.add(Point(i, j));
        }
      }
    }
    
    if (emptyCells.isEmpty) return;
    
    final random = Random();
    final cell = emptyCells[random.nextInt(emptyCells.length)];
    final value = random.nextDouble() < 0.9 ? 2 : 4;
    
    setState(() {
      _grid[cell.x][cell.y] = value;
    });
  }

  void _move(String direction) {
    if (!_isPlaying || _isGameOver) return;
    
    bool moved = false;
    
    switch (direction) {
      case 'left':
        moved = _moveLeft();
        break;
      case 'right':
        moved = _moveRight();
        break;
      case 'up':
        moved = _moveUp();
        break;
      case 'down':
        moved = _moveDown();
        break;
    }
    
    if (moved) {
      _addRandomTile();
      HapticFeedback.lightImpact();
      
      if (_checkGameOver()) {
        _endGame();
      }
    }
  }

  bool _moveLeft() {
    bool moved = false;
    
    for (int i = 0; i < _gridSize; i++) {
      final row = _grid[i].where((cell) => cell != 0).toList();
      
      for (int j = 0; j < row.length - 1; j++) {
        if (row[j] == row[j + 1]) {
          row[j] *= 2;
          _score += row[j];
          row.removeAt(j + 1);
          moved = true;
        }
      }
      
      while (row.length < _gridSize) {
        row.add(0);
      }
      
      if (_grid[i].toString() != row.toString()) {
        moved = true;
      }
      
      _grid[i] = row;
    }
    
    return moved;
  }

  bool _moveRight() {
    _reverseRows();
    final moved = _moveLeft();
    _reverseRows();
    return moved;
  }

  bool _moveUp() {
    _transpose();
    final moved = _moveLeft();
    _transpose();
    return moved;
  }

  bool _moveDown() {
    _transpose();
    _reverseRows();
    final moved = _moveLeft();
    _reverseRows();
    _transpose();
    return moved;
  }

  void _transpose() {
    final newGrid = List.generate(_gridSize, (i) => 
      List.generate(_gridSize, (j) => _grid[j][i])
    );
    _grid = newGrid;
  }

  void _reverseRows() {
    for (int i = 0; i < _gridSize; i++) {
      _grid[i] = _grid[i].reversed.toList();
    }
  }

  bool _checkGameOver() {
    // Check for empty cells
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_grid[i][j] == 0) return false;
      }
    }
    
    // Check for possible merges
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (j < _gridSize - 1 && _grid[i][j] == _grid[i][j + 1]) return false;
        if (i < _gridSize - 1 && _grid[i][j] == _grid[i + 1][j]) return false;
      }
    }
    
    return true;
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
      gameId: 'game_2048',
      score: _score,
      timestamp: DateTime.now(),
    ));
  }

  Color _getTileColor(int value) {
    switch (value) {
      case 2: return const Color(0xFFEEE4DA);
      case 4: return const Color(0xFFEDE0C8);
      case 8: return const Color(0xFFF2B179);
      case 16: return const Color(0xFFF59563);
      case 32: return const Color(0xFFF67C5F);
      case 64: return const Color(0xFFF65E3B);
      case 128: return const Color(0xFFEDCF72);
      case 256: return const Color(0xFFEDCC61);
      case 512: return const Color(0xFFEDC850);
      case 1024: return const Color(0xFFEDC53F);
      case 2048: return const Color(0xFFEDC22E);
      default: return const Color(0xFFCDC1B4);
    }
  }

  Color _getTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _move('right');
          } else if (details.primaryVelocity! < 0) {
            _move('left');
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _move('down');
          } else if (details.primaryVelocity! < 0) {
            _move('up');
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFAD961),
                const Color(0xFFF76B1C),
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
            '🎲 2048',
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
                '🎲',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 20),
              const Text(
                '2048',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Swipe to merge tiles!',
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFBBADA0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 16,
            itemBuilder: (context, index) {
              final i = index ~/ _gridSize;
              final j = index % _gridSize;
              final value = _grid[i][j];
              
              return Container(
                decoration: BoxDecoration(
                  color: _getTileColor(value),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: value != 0
                      ? Text(
                          value.toString(),
                          style: TextStyle(
                            fontSize: value >= 1000 ? 24 : 32,
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(value),
                          ),
                        )
                      : null,
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
          IconButton(
            onPressed: () => _move('up'),
            icon: const Icon(Iconsax.arrow_up_2, size: 32),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _move('left'),
                icon: const Icon(Iconsax.arrow_left_2, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(width: 60),
              IconButton(
                onPressed: () => _move('down'),
                icon: const Icon(Iconsax.arrow_down_2, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(width: 60),
              IconButton(
                onPressed: () => _move('right'),
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
                '😢',
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
