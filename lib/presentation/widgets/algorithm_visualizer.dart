import 'package:flutter/material.dart';
import 'dart:math';
import 'sorting_visualizers.dart';
import 'ds_graph_visualizers.dart';

class AlgorithmVisualizer extends StatefulWidget {
  final String algorithmId;
  final VoidCallback? onComplete;

  const AlgorithmVisualizer({
    super.key,
    required this.algorithmId,
    this.onComplete,
  });

  @override
  State<AlgorithmVisualizer> createState() => _AlgorithmVisualizerState();
}

class _AlgorithmVisualizerState extends State<AlgorithmVisualizer> with TickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildVisualization() {
    switch (widget.algorithmId) {
      // Sorting Algorithms
      case 'bubble_sort':
        return _BubbleSortVisualizer(controller: _controller, currentStep: _currentStep);
      case 'selection_sort':
        return SelectionSortVisualizer(currentStep: _currentStep);
      case 'insertion_sort':
        return InsertionSortVisualizer(currentStep: _currentStep);
      case 'merge_sort':
        return MergeSortVisualizer(currentStep: _currentStep);
      case 'quick_sort':
        return QuickSortVisualizer(currentStep: _currentStep);
      case 'heap_sort':
        return HeapSortVisualizer(currentStep: _currentStep);
      case 'counting_sort':
        return CountingSortVisualizer(currentStep: _currentStep);
      
      // Searching Algorithms
      case 'binary_search':
        return _BinarySearchVisualizer(controller: _controller, currentStep: _currentStep);
      case 'linear_search':
        return LinearSearchVisualizer(currentStep: _currentStep);
      
      // Data Structures
      case 'stack_push':
        return _StackVisualizer(controller: _controller, currentStep: _currentStep, isPush: true);
      case 'stack_pop':
        return _StackVisualizer(controller: _controller, currentStep: _currentStep, isPush: false);
      case 'queue_enqueue':
        return _QueueVisualizer(controller: _controller, currentStep: _currentStep, isEnqueue: true);
      case 'queue_dequeue':
        return _QueueVisualizer(controller: _controller, currentStep: _currentStep, isEnqueue: false);
      case 'circular_queue':
        return CircularQueueVisualizer(currentStep: _currentStep);
      case 'linked_list_insert':
        return _LinkedListVisualizer(controller: _controller, currentStep: _currentStep);
      case 'bst_insert':
        return BSTInsertVisualizer(currentStep: _currentStep);
      case 'avl_rotation':
        return AVLRotationVisualizer(currentStep: _currentStep);
      
      // Graph Algorithms
      case 'bfs':
        return _BFSVisualizer(controller: _controller, currentStep: _currentStep);
      case 'dfs':
        return _DFSVisualizer(controller: _controller, currentStep: _currentStep);
      case 'dijkstra':
        return DijkstraVisualizer(currentStep: _currentStep);
      case 'kruskal':
        return KruskalVisualizer(currentStep: _currentStep);
      case 'topological_sort':
        return TopologicalSortVisualizer(currentStep: _currentStep);
      
      default:
        return _GenericVisualizer(algorithmId: widget.algorithmId);
    }
  }

  void _playAnimation() async {
    if (_isPlaying) {
      setState(() => _isPlaying = false);
      return;
    }
    
    setState(() => _isPlaying = true);
    
    final maxSteps = _getMaxSteps();
    for (int i = _currentStep; i <= maxSteps; i++) {
      if (!mounted || !_isPlaying) break;
      
      setState(() => _currentStep = i);
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted || !_isPlaying) break;
    }
    
    if (mounted) {
      setState(() => _isPlaying = false);
      widget.onComplete?.call();
    }
  }

  int _getMaxSteps() {
    switch (widget.algorithmId) {
      case 'bubble_sort':
      case 'selection_sort':
      case 'insertion_sort':
        return 8;
      case 'merge_sort':
      case 'quick_sort':
      case 'heap_sort':
        return 10;
      case 'counting_sort':
        return 6;
      case 'binary_search':
      case 'linear_search':
        return 6;
      case 'stack_push':
      case 'stack_pop':
      case 'queue_enqueue':
      case 'queue_dequeue':
      case 'circular_queue':
        return 5;
      case 'linked_list_insert':
        return 4;
      case 'bst_insert':
        return 6;
      case 'avl_rotation':
        return 5;
      case 'bfs':
      case 'dfs':
        return 7;
      case 'dijkstra':
        return 8;
      case 'kruskal':
        return 7;
      case 'topological_sort':
        return 6;
      default:
        return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: _buildVisualization(),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filled(
                    onPressed: _isPlaying ? null : () {
                      setState(() => _currentStep = 0);
                    },
                    icon: const Icon(Icons.replay),
                    tooltip: 'Reset',
                  ),
                  IconButton.filled(
                    onPressed: _isPlaying ? null : () {
                      setState(() => _currentStep = max(0, _currentStep - 1));
                    },
                    icon: const Icon(Icons.skip_previous),
                    tooltip: 'Previous Step',
                  ),
                  IconButton.filled(
                    onPressed: _playAnimation,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFDA7809),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(20),
                    ),
                    tooltip: _isPlaying ? 'Pause' : 'Play',
                  ),
                  IconButton.filled(
                    onPressed: _isPlaying ? null : () {
                      setState(() => _currentStep = min(_getMaxSteps(), _currentStep + 1));
                    },
                    icon: const Icon(Icons.skip_next),
                    tooltip: 'Next Step',
                  ),
                  IconButton.filled(
                    onPressed: _isPlaying ? null : () {
                      setState(() => _currentStep = _getMaxSteps());
                    },
                    icon: const Icon(Icons.fast_forward),
                    tooltip: 'End',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Step $_currentStep of ${_getMaxSteps()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Bubble Sort Visualization
class _BubbleSortVisualizer extends StatelessWidget {
  final AnimationController controller;
  final int currentStep;

  const _BubbleSortVisualizer({required this.controller, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final List<int> array = [64, 34, 25, 12, 22, 11, 90];
    final sortedArray = List<int>.from(array);
    
    // Simulate sorting steps
    for (int i = 0; i < currentStep && i < array.length; i++) {
      for (int j = 0; j < array.length - 1 - i; j++) {
        if (sortedArray[j] > sortedArray[j + 1]) {
          final temp = sortedArray[j];
          sortedArray[j] = sortedArray[j + 1];
          sortedArray[j + 1] = temp;
        }
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Bubble Sort Animation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(sortedArray.length, (index) {
            final height = sortedArray[index].toDouble();
            final isComparing = currentStep > 0 && index < 2;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: height * 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isComparing
                      ? [Colors.orange, Colors.deepOrange]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${sortedArray[index]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text(
          currentStep == 0
              ? 'Initial array'
              : 'Pass $currentStep: Comparing and swapping',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

// Binary Search Visualization
class _BinarySearchVisualizer extends StatelessWidget {
  final AnimationController controller;
  final int currentStep;

  const _BinarySearchVisualizer({required this.controller, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final List<int> array = [2, 5, 8, 12, 16, 23, 38, 45, 56, 67, 78];
    final target = 23;
    
    int low = 0;
    int high = array.length - 1;
    int mid = (low + high) ~/ 2;
    
    // Simulate search steps
    for (int i = 0; i < currentStep; i++) {
      mid = (low + high) ~/ 2;
      if (array[mid] == target) break;
      if (array[mid] < target) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Binary Search Animation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text('Searching for: $target', style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(array.length, (index) {
            final isLow = index == low && currentStep > 0;
            final isHigh = index == high && currentStep > 0;
            final isMid = index == mid && currentStep > 0;
            final isFound = array[index] == target && currentStep > 3;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isFound
                    ? Colors.green
                    : isMid
                        ? Colors.orange
                        : (isLow || isHigh)
                            ? Colors.blue.shade200
                            : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isMid ? Colors.orange : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  '${array[index]}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (isMid || isFound) ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text(
          currentStep == 0
              ? 'Start search'
              : 'Step $currentStep: Checking middle element',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

// Stack Visualization
class _StackVisualizer extends StatelessWidget {
  final AnimationController controller;
  final int currentStep;
  final bool isPush;

  const _StackVisualizer({
    required this.controller,
    required this.currentStep,
    required this.isPush,
  });

  @override
  Widget build(BuildContext context) {
    final stackItems = isPush
        ? List.generate(min(currentStep, 5), (i) => 10 + i * 5)
        : List.generate(max(0, 5 - currentStep), (i) => 10 + i * 5);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isPush ? 'Stack Push Operation' : 'Stack Pop Operation',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Container(
          width: 120,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ...stackItems.reversed.map((item) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 50,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$item',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Top → ${stackItems.isEmpty ? "Empty" : stackItems.last}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Queue Visualization
class _QueueVisualizer extends StatelessWidget {
  final AnimationController controller;
  final int currentStep;
  final bool isEnqueue;

  const _QueueVisualizer({
    required this.controller,
    required this.currentStep,
    required this.isEnqueue,
  });

  @override
  Widget build(BuildContext context) {
    final queueItems = isEnqueue
        ? List.generate(min(currentStep, 5), (i) => 10 + i * 5)
        : List.generate(max(0, 5 - currentStep), (i) => 10 + (i + currentStep) * 5);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isEnqueue ? 'Queue Enqueue Operation' : 'Queue Dequeue Operation',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Front →', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              height: 80,
              constraints: const BoxConstraints(maxWidth: 300),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: queueItems.map((item) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$item',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(width: 8),
            const Text('← Rear', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

// BFS Visualization
class _BFSVisualizer extends StatelessWidget {
  final AnimationController controller;
  final int currentStep;

  const _BFSVisualizer({required this.controller, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final visited = List.generate(min(currentStep + 1, 7), (i) => i);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Breadth First Search (BFS)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        CustomPaint(
          size: const Size(300, 250),
          painter: _GraphPainter(visited: visited, isBFS: true),
        ),
        const SizedBox(height: 16),
        Text(
          'Visited: ${visited.join(" → ")}',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

// DFS Visualization
class _DFSVisualizer extends StatelessWidget {
  final AnimationController controller;
  final int currentStep;

  const _DFSVisualizer({required this.controller, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final visited = List.generate(min(currentStep + 1, 7), (i) => i);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Depth First Search (DFS)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        CustomPaint(
          size: const Size(300, 250),
          painter: _GraphPainter(visited: visited, isBFS: false),
        ),
        const SizedBox(height: 16),
        Text(
          'Visited: ${visited.join(" → ")}',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

// Linked List Visualization
class _LinkedListVisualizer extends StatelessWidget {
  final AnimationController controller;
  final int currentStep;

  const _LinkedListVisualizer({required this.controller, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final nodes = [10, 20, 30, 40];
    final showNewNode = currentStep > 0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Linked List Insert at Beginning',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showNewNode) ...[
              _buildNode(5, Colors.orange, currentStep > 1),
              if (currentStep > 1) _buildArrow(),
            ],
            ...nodes.asMap().entries.map((entry) {
              return Row(
                children: [
                  _buildNode(entry.value, Colors.blue, false),
                  if (entry.key < nodes.length - 1) _buildArrow(),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          currentStep == 0
              ? 'Original list'
              : currentStep == 1
                  ? 'Create new node (5)'
                  : 'Link new node to head',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildNode(int value, Color color, bool isHighlighted) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted ? Colors.orange : Colors.transparent,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward, size: 20),
    );
  }
}

// Generic Visualizer for algorithms without custom visualization
class _GenericVisualizer extends StatelessWidget {
  final String algorithmId;

  const _GenericVisualizer({required this.algorithmId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Visual animation coming soon!',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete the step ordering game to learn',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Graph Painter for BFS/DFS
class _GraphPainter extends CustomPainter {
  final List<int> visited;
  final bool isBFS;

  _GraphPainter({required this.visited, required this.isBFS});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Node positions
    final nodes = {
      0: Offset(size.width / 2, 30),
      1: Offset(size.width / 4, 100),
      2: Offset(size.width * 3 / 4, 100),
      3: Offset(size.width / 6, 170),
      4: Offset(size.width / 3, 170),
      5: Offset(size.width * 2 / 3, 170),
      6: Offset(size.width * 5 / 6, 170),
    };

    // Edges
    final edges = [
      [0, 1], [0, 2],
      [1, 3], [1, 4],
      [2, 5], [2, 6],
    ];

    // Draw edges
    paint.color = Colors.grey;
    for (final edge in edges) {
      canvas.drawLine(nodes[edge[0]]!, nodes[edge[1]]!, paint);
    }

    // Draw nodes
    for (final entry in nodes.entries) {
      final isVisited = visited.contains(entry.key);
      final isCurrent = visited.isNotEmpty && visited.last == entry.key;
      
      paint.style = PaintingStyle.fill;
      paint.color = isCurrent
          ? Colors.orange
          : isVisited
              ? Colors.green
              : Colors.grey.shade300;
      
      canvas.drawCircle(entry.value, 20, paint);
      
      // Draw node number
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${entry.key}',
          style: TextStyle(
            color: isVisited ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        entry.value - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
