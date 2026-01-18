import 'package:flutter/material.dart';
import 'dart:math';

// Circular Queue Visualization
class CircularQueueVisualizer extends StatelessWidget {
  final int currentStep;

  const CircularQueueVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final queueSize = 6;
    final items = List.generate(min(currentStep + 1, queueSize), (i) => 10 + i * 5);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Circular Queue',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _CircularQueuePainter(items: items, size: queueSize),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Front → Rear (Circular)',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CircularQueuePainter extends CustomPainter {
  final List<int> items;
  final int size;

  _CircularQueuePainter({required this.items, required this.size});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw circle slots
    for (int i = 0; i < this.size; i++) {
      final angle = (i * 2 * pi / this.size) - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      final hasItem = i < items.length;
      paint.color = hasItem ? const Color(0xFFEC4899) : Colors.grey.shade300;
      
      canvas.drawCircle(Offset(x, y), 25, paint);
      
      if (hasItem) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${items[i]}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// BST Insert Visualization
class BSTInsertVisualizer extends StatelessWidget {
  final int currentStep;

  const BSTInsertVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Binary Search Tree Insert',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        CustomPaint(
          size: const Size(300, 250),
          painter: _BSTInsertPainter(currentStep: currentStep),
        ),
        const SizedBox(height: 16),
        Text(
          currentStep == 0
              ? 'Inserting 15 into BST'
              : currentStep < 3
                  ? 'Traversing: 15 < 20, go left'
                  : currentStep < 5
                      ? 'Traversing: 15 > 10, go right'
                      : 'Inserted 15 as right child of 10',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class _BSTInsertPainter extends CustomPainter {
  final int currentStep;

  _BSTInsertPainter({required this.currentStep});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Node positions
    final nodes = {
      20: Offset(size.width / 2, 30),
      10: Offset(size.width / 3, 100),
      30: Offset(size.width * 2 / 3, 100),
      5: Offset(size.width / 6, 170),
      if (currentStep >= 5) 15: Offset(size.width / 2.5, 170),
      25: Offset(size.width * 7 / 12, 170),
      35: Offset(size.width * 5 / 6, 170),
    };

    // Draw edges
    paint.color = Colors.grey;
    canvas.drawLine(nodes[20]!, nodes[10]!, paint);
    canvas.drawLine(nodes[20]!, nodes[30]!, paint);
    canvas.drawLine(nodes[10]!, nodes[5]!, paint);
    if (currentStep >= 5) {
      canvas.drawLine(nodes[10]!, nodes[15]!, paint);
    }
    canvas.drawLine(nodes[30]!, nodes[25]!, paint);
    canvas.drawLine(nodes[30]!, nodes[35]!, paint);

    // Draw nodes
    for (final entry in nodes.entries) {
      final isNew = entry.key == 15;
      final isPath = (entry.key == 20 && currentStep >= 1) ||
                     (entry.key == 10 && currentStep >= 3);
      
      paint.style = PaintingStyle.fill;
      paint.color = isNew
          ? Colors.green
          : isPath
              ? Colors.orange
              : const Color(0xFF6366F1);
      
      canvas.drawCircle(entry.value, 20, paint);
      
      // Draw value
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${entry.key}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
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

// AVL Rotation Visualization
class AVLRotationVisualizer extends StatelessWidget {
  final int currentStep;

  const AVLRotationVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'AVL Tree Rotation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        if (currentStep < 3)
          _buildUnbalancedTree()
        else
          _buildBalancedTree(),
        const SizedBox(height: 24),
        Text(
          currentStep == 0
              ? 'Unbalanced tree detected'
              : currentStep < 3
                  ? 'Calculating balance factors'
                  : 'Performing right rotation',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildUnbalancedTree() {
    return Column(
      children: [
        _buildNode(30, Colors.red),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNode(20, Colors.orange),
            const SizedBox(width: 60),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNode(10, const Color(0xFF6366F1)),
            const SizedBox(width: 120),
          ],
        ),
      ],
    );
  }

  Widget _buildBalancedTree() {
    return Column(
      children: [
        _buildNode(20, Colors.green),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNode(10, const Color(0xFF6366F1)),
            const SizedBox(width: 60),
            _buildNode(30, const Color(0xFF6366F1)),
          ],
        ),
      ],
    );
  }

  Widget _buildNode(int value, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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
}

// Dijkstra's Algorithm Visualization
class DijkstraVisualizer extends StatelessWidget {
  final int currentStep;

  const DijkstraVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Dijkstra's Shortest Path",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        CustomPaint(
          size: const Size(300, 250),
          painter: _DijkstraPainter(currentStep: currentStep),
        ),
        const SizedBox(height: 16),
        Text(
          currentStep == 0
              ? 'Initialize distances'
              : 'Processing node, updating distances',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class _DijkstraPainter extends CustomPainter {
  final int currentStep;

  _DijkstraPainter({required this.currentStep});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Node positions
    final nodes = {
      0: Offset(size.width / 4, 50),
      1: Offset(size.width * 3 / 4, 50),
      2: Offset(size.width / 4, 150),
      3: Offset(size.width * 3 / 4, 150),
    };

    final distances = [0, 999, 999, 999];
    if (currentStep > 0) distances[1] = 4;
    if (currentStep > 2) distances[2] = 2;
    if (currentStep > 4) distances[3] = 7;

    // Draw edges with weights
    paint.color = Colors.grey;
    _drawEdge(canvas, nodes[0]!, nodes[1]!, '4', paint);
    _drawEdge(canvas, nodes[0]!, nodes[2]!, '2', paint);
    _drawEdge(canvas, nodes[1]!, nodes[3]!, '3', paint);
    _drawEdge(canvas, nodes[2]!, nodes[3]!, '5', paint);

    // Draw nodes
    for (final entry in nodes.entries) {
      final isVisited = entry.key <= currentStep;
      final isCurrent = entry.key == currentStep;
      
      paint.style = PaintingStyle.fill;
      paint.color = isCurrent
          ? Colors.orange
          : isVisited
              ? Colors.green
              : Colors.grey.shade300;
      
      canvas.drawCircle(entry.value, 25, paint);
      
      // Draw distance
      final textPainter = TextPainter(
        text: TextSpan(
          text: distances[entry.key] == 999 ? '∞' : '${distances[entry.key]}',
          style: TextStyle(
            color: isVisited ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
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

  void _drawEdge(Canvas canvas, Offset start, Offset end, String weight, Paint paint) {
    canvas.drawLine(start, end, paint);
    
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final textPainter = TextPainter(
      text: TextSpan(
        text: weight,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          backgroundColor: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, mid - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Kruskal's Algorithm Visualization
class KruskalVisualizer extends StatelessWidget {
  final int currentStep;

  const KruskalVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Kruskal's MST Algorithm",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        CustomPaint(
          size: const Size(300, 250),
          painter: _KruskalPainter(currentStep: currentStep),
        ),
        const SizedBox(height: 16),
        Text(
          currentStep == 0
              ? 'Sort edges by weight'
              : 'Adding edge to MST (no cycle)',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class _KruskalPainter extends CustomPainter {
  final int currentStep;

  _KruskalPainter({required this.currentStep});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Node positions
    final nodes = {
      0: Offset(size.width / 4, 50),
      1: Offset(size.width * 3 / 4, 50),
      2: Offset(size.width / 4, 150),
      3: Offset(size.width * 3 / 4, 150),
    };

    // Edges with weights (sorted)
    final edges = [
      [0, 2, 1], // weight 1
      [0, 1, 2], // weight 2
      [1, 3, 3], // weight 3
      [2, 3, 4], // weight 4
    ];

    // Draw edges
    for (int i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final isInMST = i < currentStep;
      
      paint.color = isInMST ? Colors.green : Colors.grey.shade400;
      paint.strokeWidth = isInMST ? 4 : 2;
      
      canvas.drawLine(nodes[edge[0]]!, nodes[edge[1]]!, paint);
      
      // Draw weight
      final mid = Offset(
        (nodes[edge[0]]!.dx + nodes[edge[1]]!.dx) / 2,
        (nodes[edge[0]]!.dy + nodes[edge[1]]!.dy) / 2,
      );
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${edge[2]}',
          style: TextStyle(
            color: isInMST ? Colors.green : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            backgroundColor: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, mid - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Draw nodes
    paint.style = PaintingStyle.fill;
    for (final entry in nodes.entries) {
      paint.color = const Color(0xFF6366F1);
      canvas.drawCircle(entry.value, 20, paint);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${entry.key}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
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

// Topological Sort Visualization
class TopologicalSortVisualizer extends StatelessWidget {
  final int currentStep;

  const TopologicalSortVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final sorted = List.generate(min(currentStep + 1, 6), (i) => i);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Topological Sort (DAG)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        CustomPaint(
          size: const Size(300, 200),
          painter: _TopologicalPainter(sorted: sorted),
        ),
        const SizedBox(height: 16),
        Text(
          'Sorted order: ${sorted.join(" → ")}',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class _TopologicalPainter extends CustomPainter {
  final List<int> sorted;

  _TopologicalPainter({required this.sorted});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Node positions (DAG layout)
    final nodes = {
      0: Offset(size.width / 6, 50),
      1: Offset(size.width / 2, 50),
      2: Offset(size.width * 5 / 6, 50),
      3: Offset(size.width / 3, 150),
      4: Offset(size.width * 2 / 3, 150),
      5: Offset(size.width / 2, 200),
    };

    // Draw directed edges
    paint.color = Colors.grey;
    _drawArrow(canvas, nodes[0]!, nodes[3]!, paint);
    _drawArrow(canvas, nodes[1]!, nodes[3]!, paint);
    _drawArrow(canvas, nodes[1]!, nodes[4]!, paint);
    _drawArrow(canvas, nodes[2]!, nodes[4]!, paint);
    _drawArrow(canvas, nodes[3]!, nodes[5]!, paint);
    _drawArrow(canvas, nodes[4]!, nodes[5]!, paint);

    // Draw nodes
    paint.style = PaintingStyle.fill;
    for (final entry in nodes.entries) {
      final isSorted = sorted.contains(entry.key);
      
      paint.color = isSorted ? Colors.green : Colors.grey.shade300;
      canvas.drawCircle(entry.value, 20, paint);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${entry.key}',
          style: TextStyle(
            color: isSorted ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
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

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    
    // Draw arrowhead
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowSize = 10.0;
    
    final p1 = Offset(
      end.dx - arrowSize * cos(angle - pi / 6),
      end.dy - arrowSize * sin(angle - pi / 6),
    );
    final p2 = Offset(
      end.dx - arrowSize * cos(angle + pi / 6),
      end.dy - arrowSize * sin(angle + pi / 6),
    );
    
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    
    paint.style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
    paint.style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
