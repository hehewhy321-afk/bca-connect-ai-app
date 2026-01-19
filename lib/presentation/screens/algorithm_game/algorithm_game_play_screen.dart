import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/models/algorithm_model.dart';
import '../../../data/repositories/algorithm_repository.dart';
import '../../widgets/algorithm_visualizer.dart';

class AlgorithmGamePlayScreen extends StatefulWidget {
  final AlgorithmModel algorithm;

  const AlgorithmGamePlayScreen({super.key, required this.algorithm});

  @override
  State<AlgorithmGamePlayScreen> createState() => _AlgorithmGamePlayScreenState();
}

class _AlgorithmGamePlayScreenState extends State<AlgorithmGamePlayScreen> with TickerProviderStateMixin {
  final _repository = AlgorithmRepository();
  
  List<AlgorithmStep?> _placedSteps = [];
  List<AlgorithmStep> _availableSteps = [];
  
  int _mistakes = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isCompleted = false;
  bool _showExplanation = false;
  bool _showVisualizer = false;
  int _hintsUsed = 0;
  final int _maxHints = 3;
  
  late AnimationController _shakeController;
  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _initializeGame() {
    // Initialize empty slots
    _placedSteps = List.filled(widget.algorithm.steps.length, null);
    
    // Shuffle available steps
    _availableSteps = List.from(widget.algorithm.steps)..shuffle(Random());
    
    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isCompleted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _onStepPlaced(AlgorithmStep step, int targetIndex) {
    setState(() {
      // Remove from available
      _availableSteps.remove(step);
      
      // Place in slot
      _placedSteps[targetIndex] = step;
      
      // Check if correct
      if (step.order != targetIndex + 1) {
        _mistakes++;
        _shakeController.forward().then((_) => _shakeController.reset());
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      
      // Check if completed
      if (_availableSteps.isEmpty) {
        _checkCompletion();
      }
    });
  }

  void _onStepRemoved(int index) {
    setState(() {
      final step = _placedSteps[index];
      if (step != null) {
        _placedSteps[index] = null;
        _availableSteps.add(step);
      }
    });
  }

  void _checkCompletion() {
    bool allCorrect = true;
    for (int i = 0; i < _placedSteps.length; i++) {
      if (_placedSteps[i]?.order != i + 1) {
        allCorrect = false;
        break;
      }
    }
    
    if (allCorrect) {
      _timer?.cancel();
      _isCompleted = true;
      _successController.forward();
      HapticFeedback.mediumImpact();
      _saveProgress();
      _showCompletionDialog();
    }
  }

  int _calculateStars() {
    if (_mistakes == 0 && _elapsedSeconds < 30) return 3;
    if (_mistakes < 3 && _elapsedSeconds < 60) return 2;
    return 1;
  }

  Future<void> _saveProgress() async {
    final stars = _calculateStars();
    final existingProgress = await _repository.getProgress(widget.algorithm.id);
    
    // Only save if better than previous
    if (existingProgress == null || 
        stars > existingProgress.stars ||
        (stars == existingProgress.stars && _elapsedSeconds < existingProgress.bestTime)) {
      final progress = GameProgress(
        algorithmId: widget.algorithm.id,
        bestTime: _elapsedSeconds,
        bestMistakes: _mistakes,
        stars: stars,
        completed: true,
        lastPlayed: DateTime.now(),
      );
      await _repository.saveProgress(progress);
    }
  }

  void _showCompletionDialog() {
    final stars = _calculateStars();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Iconsax.cup, color: ModernTheme.primaryOrange),
            const SizedBox(width: 8),
            const Text('Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Icon(
                  index < stars ? Iconsax.star5 : Iconsax.star,
                  size: 32,
                  color: index < stars ? Colors.amber : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildStat('⏱️', 'Time', '${_elapsedSeconds}s'),
            const SizedBox(height: 8),
            _buildStat('❌', 'Mistakes', _mistakes.toString()),
            const SizedBox(height: 8),
            _buildStat('💡', 'Hints Used', '$_hintsUsed/$_maxHints'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _showVisualizer = true);
            },
            child: const Text('Watch Animation'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _showExplanation = true);
            },
            child: const Text('View Explanation'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String emoji, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showHint() {
    if (_hintsUsed >= _maxHints) return;
    
    // Find first empty slot
    int? emptySlot;
    for (int i = 0; i < _placedSteps.length; i++) {
      if (_placedSteps[i] == null) {
        emptySlot = i;
        break;
      }
    }
    
    if (emptySlot == null) return;
    
    // Find correct step for this slot
    final correctStep = widget.algorithm.steps.firstWhere(
      (step) => step.order == emptySlot! + 1,
    );
    
    setState(() => _hintsUsed++);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Iconsax.lamp_on, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Hint'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${emptySlot! + 1} should be:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Text(correctStep.text),
            ),
            const SizedBox(height: 12),
            Text(
              'Hints remaining: ${_maxHints - _hintsUsed}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizerView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Algorithm Animation'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _showVisualizer = false),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Text(
                  widget.algorithm.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getExampleProblem(widget.algorithm.id),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Watch how the algorithm solves this step by step',
                    style: TextStyle(
                      fontSize: 11,
                      color: ModernTheme.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AlgorithmVisualizer(
              algorithmId: widget.algorithm.id,
              onComplete: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Animation completed!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  String _getExampleProblem(String algorithmId) {
    switch (algorithmId) {
      // Sorting
      case 'bubble_sort':
        return '📊 Example: Sort [64, 34, 25, 12, 22, 11, 90] in ascending order';
      case 'selection_sort':
        return '📊 Example: Sort [29, 10, 14, 37, 13] using Selection Sort';
      case 'insertion_sort':
        return '📊 Example: Sort [12, 11, 13, 5, 6] by inserting elements';
      case 'merge_sort':
        return '📊 Example: Sort [38, 27, 43, 3, 9, 82, 10] using divide & conquer';
      case 'quick_sort':
        return '📊 Example: Sort [10, 7, 8, 9, 1, 5] using pivot partitioning';
      case 'heap_sort':
        return '📊 Example: Sort [4, 10, 3, 5, 1] using heap structure';
      case 'counting_sort':
        return '📊 Example: Sort [1, 4, 1, 2, 7, 5, 2] using counting technique';
      
      // Searching
      case 'binary_search':
        return '🔍 Example: Find 23 in sorted array [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]';
      case 'linear_search':
        return '🔍 Example: Find 31 in array [10, 23, 45, 70, 11, 15, 31, 89]';
      
      // Stack
      case 'stack_push':
        return '📚 Example: Push elements [5, 10, 15, 20] onto an empty stack';
      case 'stack_pop':
        return '📚 Example: Pop 2 elements from stack [5, 10, 15, 20]';
      
      // Queue
      case 'queue_enqueue':
        return '🎫 Example: Enqueue [A, B, C, D] into an empty queue';
      case 'queue_dequeue':
        return '🎫 Example: Dequeue 2 elements from queue [A, B, C, D]';
      case 'circular_queue':
        return '🔄 Example: Circular queue operations with size 5';
      
      // Linked List
      case 'linked_list_insert':
        return '🔗 Example: Insert 25 at position 2 in list [10→20→30→40]';
      
      // Trees
      case 'bst_insert':
        return '🌳 Example: Insert [50, 30, 70, 20, 40, 60, 80] into BST';
      case 'avl_rotation':
        return '🌳 Example: Balance AVL tree after inserting [10, 20, 30]';
      
      // Graphs
      case 'bfs':
        return '🗺️ Example: BFS traversal starting from node A in graph';
      case 'dfs':
        return '🗺️ Example: DFS traversal starting from node A in graph';
      case 'dijkstra':
        return '🗺️ Example: Find shortest path from A to E in weighted graph';
      case 'kruskal':
        return '🗺️ Example: Find Minimum Spanning Tree of connected graph';
      case 'topological_sort':
        return '🗺️ Example: Order tasks with dependencies [A→B, B→C, A→D]';
      
      default:
        return '📖 Watch the algorithm in action with a real example';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showVisualizer) {
      return _buildVisualizerView();
    }
    
    if (_showExplanation) {
      return _buildExplanationView();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.algorithm.name),
        actions: [
          // Hint Button
          IconButton(
            icon: Badge(
              label: Text('${_maxHints - _hintsUsed}'),
              child: const Icon(Iconsax.lamp_on),
            ),
            onPressed: _hintsUsed < _maxHints ? _showHint : null,
            tooltip: 'Get Hint',
          ),
          // Visualizer Button
          IconButton(
            icon: const Icon(Iconsax.eye),
            onPressed: () => setState(() => _showVisualizer = true),
            tooltip: 'Watch Animation',
          ),
          // Timer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Iconsax.timer_1, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_elapsedSeconds}s',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatChip(Iconsax.task_square, '${_placedSteps.where((s) => s != null).length}/${widget.algorithm.steps.length}', 'Placed'),
                _buildStatChip(Iconsax.close_circle, _mistakes.toString(), 'Mistakes'),
                _buildStatChip(Iconsax.star, _calculateStars().toString(), 'Stars'),
              ],
            ),
          ),
          
          // Target Slots (Top)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Arrange in Correct Order',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _placedSteps.length,
                      itemBuilder: (context, index) => _buildTargetSlot(index),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Divider
          Container(
            height: 2,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          
          // Available Steps (Bottom) - Dynamic Height
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Drag Steps Here (${_availableSteps.length} remaining)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _availableSteps.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            '✅ All steps placed!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _availableSteps
                            .map((step) => _buildDraggableStep(step))
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ModernTheme.primaryOrange),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetSlot(int index) {
    final step = _placedSteps[index];
    final isCorrect = step?.order == index + 1;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DragTarget<AlgorithmStep>(
        onWillAcceptWithDetails: (details) => step == null,
        onAcceptWithDetails: (details) => _onStepPlaced(details.data, index),
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          
          return AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final shake = sin(_shakeController.value * pi * 4) * 5;
              
              return Transform.translate(
                offset: Offset(step != null && !isCorrect ? shake : 0, 0),
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: step == null
                        ? (isHovering
                            ? ModernTheme.primaryOrange.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.surface)
                        : (isCorrect
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: step == null
                          ? (isHovering
                              ? ModernTheme.primaryOrange
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))
                          : (isCorrect ? Colors.green : Colors.red),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: step == null
                              ? Theme.of(context).colorScheme.surfaceContainerHighest
                              : (isCorrect ? Colors.green : Colors.red),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: step == null
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: step == null
                            ? Text(
                                'Drop step here',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Text(
                                step.text,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (step != null)
                        IconButton(
                          icon: const Icon(Iconsax.close_circle, size: 20),
                          onPressed: () => _onStepRemoved(index),
                          color: Colors.red,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDraggableStep(AlgorithmStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      child: Draggable<AlgorithmStep>(
        data: step,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: MediaQuery.of(context).size.width - 80,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ModernTheme.primaryOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step.text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildStepCard(step),
        ),
        child: _buildStepCard(step),
      ),
    );
  }

  Widget _buildStepCard(AlgorithmStep step) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.menu,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.text,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explanation'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.algorithm.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.algorithm.explanation,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Correct Order:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.algorithm.steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: ModernTheme.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${step.order}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(step.text, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            )),
            if (widget.algorithm.commonMistake != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.warning_2, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Common Mistake',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(widget.algorithm.commonMistake!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back to Categories'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
