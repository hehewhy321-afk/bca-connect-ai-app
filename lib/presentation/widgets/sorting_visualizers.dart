import 'package:flutter/material.dart';
import 'dart:math';

// Selection Sort Visualization
class SelectionSortVisualizer extends StatelessWidget {
  final int currentStep;

  const SelectionSortVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final List<int> array = [64, 25, 12, 22, 11, 34, 90];
    final sortedArray = List<int>.from(array);
    
    // Simulate sorting steps
    for (int i = 0; i < min(currentStep, array.length); i++) {
      int minIdx = i;
      for (int j = i + 1; j < sortedArray.length; j++) {
        if (sortedArray[j] < sortedArray[minIdx]) {
          minIdx = j;
        }
      }
      if (minIdx != i) {
        final temp = sortedArray[i];
        sortedArray[i] = sortedArray[minIdx];
        sortedArray[minIdx] = temp;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Selection Sort Animation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(sortedArray.length, (index) {
            final height = sortedArray[index].toDouble();
            final isMinimum = currentStep > 0 && index == currentStep - 1;
            final isSorted = index < currentStep;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: height * 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isSorted
                      ? [Colors.green, Colors.green.shade700]
                      : isMinimum
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
              : 'Pass $currentStep: Finding minimum and swapping',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

// Insertion Sort Visualization
class InsertionSortVisualizer extends StatelessWidget {
  final int currentStep;

  const InsertionSortVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final List<int> array = [12, 11, 13, 5, 6, 7];
    final sortedArray = List<int>.from(array);
    
    // Simulate insertion sort
    for (int i = 1; i <= min(currentStep, array.length - 1); i++) {
      int key = sortedArray[i];
      int j = i - 1;
      while (j >= 0 && sortedArray[j] > key) {
        sortedArray[j + 1] = sortedArray[j];
        j--;
      }
      sortedArray[j + 1] = key;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Insertion Sort Animation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(sortedArray.length, (index) {
            final height = sortedArray[index].toDouble();
            final isSorted = index <= currentStep;
            final isCurrent = index == currentStep;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 45,
              height: height * 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isCurrent
                      ? [Colors.orange, Colors.deepOrange]
                      : isSorted
                          ? [Colors.green, Colors.green.shade700]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${sortedArray[index]}',
                  style: TextStyle(
                    color: isSorted ? Colors.white : Colors.black,
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
              ? 'Initial array - first element is sorted'
              : 'Inserting element at position $currentStep',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

// Merge Sort Visualization
class MergeSortVisualizer extends StatelessWidget {
  final int currentStep;

  const MergeSortVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Merge Sort Animation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildMergeSteps(currentStep),
        const SizedBox(height: 24),
        Text(
          currentStep == 0
              ? 'Original array'
              : currentStep < 4
                  ? 'Dividing: Step $currentStep'
                  : 'Merging: Step ${currentStep - 3}',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMergeSteps(int step) {
    final array = [38, 27, 43, 3, 9, 82, 10];
    
    if (step == 0) {
      return _buildArrayRow(array, []);
    } else if (step == 1) {
      return Column(
        children: [
          _buildArrayRow([38, 27, 43, 3], []),
          const SizedBox(height: 8),
          _buildArrayRow([9, 82, 10], []),
        ],
      );
    } else if (step >= 2 && step < 6) {
      return Column(
        children: [
          _buildArrayRow([38, 27], []),
          const SizedBox(height: 8),
          _buildArrayRow([43, 3], []),
          const SizedBox(height: 8),
          _buildArrayRow([9, 82], []),
          const SizedBox(height: 8),
          _buildArrayRow([10], []),
        ],
      );
    } else {
      final sorted = [3, 9, 10, 27, 38, 43, 82];
      return _buildArrayRow(sorted.sublist(0, min(step - 2, sorted.length)), []);
    }
  }

  Widget _buildArrayRow(List<int> array, List<int> highlighted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: array.map((number) {
        final isHighlighted = highlighted.contains(number);
        return Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isHighlighted ? Colors.orange : const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Quick Sort Visualization
class QuickSortVisualizer extends StatelessWidget {
  final int currentStep;

  const QuickSortVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final List<int> array = [10, 80, 30, 90, 40, 50, 70];
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Quick Sort Animation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(array.length, (index) {
            final height = array[index].toDouble();
            final isPivot = index == array.length - 1 && currentStep > 0;
            final isPartitioned = currentStep > 3 && index < 3;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isPivot
                      ? [Colors.red, Colors.red.shade700]
                      : isPartitioned
                          ? [Colors.green, Colors.green.shade700]
                          : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${array[index]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text(
          currentStep == 0
              ? 'Choose pivot (last element)'
              : currentStep < 5
                  ? 'Partitioning around pivot'
                  : 'Recursively sorting partitions',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

// Heap Sort Visualization
class HeapSortVisualizer extends StatelessWidget {
  final int currentStep;

  const HeapSortVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Heap Sort Animation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        CustomPaint(
          size: const Size(300, 200),
          painter: _HeapPainter(currentStep: currentStep),
        ),
        const SizedBox(height: 24),
        Text(
          currentStep == 0
              ? 'Building max heap'
              : currentStep < 5
                  ? 'Heapifying: Step $currentStep'
                  : 'Extracting max and sorting',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class _HeapPainter extends CustomPainter {
  final int currentStep;

  _HeapPainter({required this.currentStep});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    // Draw heap as tree
    final nodes = {
      0: Offset(size.width / 2, 30),
      1: Offset(size.width / 3, 100),
      2: Offset(size.width * 2 / 3, 100),
      3: Offset(size.width / 6, 170),
      4: Offset(size.width / 2.5, 170),
    };

    final values = [90, 80, 70, 60, 50];

    // Draw edges
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.grey;
    canvas.drawLine(nodes[0]!, nodes[1]!, paint);
    canvas.drawLine(nodes[0]!, nodes[2]!, paint);
    canvas.drawLine(nodes[1]!, nodes[3]!, paint);
    canvas.drawLine(nodes[1]!, nodes[4]!, paint);

    // Draw nodes
    for (final entry in nodes.entries) {
      final isProcessed = entry.key < currentStep;
      
      paint.style = PaintingStyle.fill;
      paint.color = isProcessed ? Colors.green : const Color(0xFF6366F1);
      
      canvas.drawCircle(entry.value, 20, paint);
      
      // Draw value
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${values[entry.key]}',
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

// Counting Sort Visualization
class CountingSortVisualizer extends StatelessWidget {
  final int currentStep;

  const CountingSortVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final array = [4, 2, 2, 8, 3, 3, 1];
    final maxVal = 8;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Counting Sort Animation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (currentStep == 0) ...[
          const Text('Original Array:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildArrayRow(array),
        ] else if (currentStep < 3) ...[
          const Text('Count Array:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildCountArray(maxVal, currentStep),
        ] else ...[
          const Text('Sorted Array:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildArrayRow([1, 2, 2, 3, 3, 4, 8]),
        ],
        const SizedBox(height: 24),
        Text(
          currentStep == 0
              ? 'Input array'
              : currentStep < 3
                  ? 'Counting occurrences'
                  : 'Placing in sorted order',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildArrayRow(List<int> array) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: array.map((number) => Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCountArray(int max, int step) {
    final counts = List.filled(max + 1, 0);
    if (step > 1) {
      counts[1] = 1;
      counts[2] = 2;
      counts[3] = 2;
      counts[4] = 1;
      counts[8] = 1;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(min(9, max + 1), (i) => Column(
        children: [
          Text('$i', style: const TextStyle(fontSize: 10)),
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: counts[i] > 0 ? Colors.orange : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${counts[i]}',
                style: TextStyle(
                  color: counts[i] > 0 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}

// Linear Search Visualization
class LinearSearchVisualizer extends StatelessWidget {
  final int currentStep;

  const LinearSearchVisualizer({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final List<int> array = [10, 23, 45, 70, 11, 15, 36, 48];
    final target = 36;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Linear Search Animation',
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
            final isCurrent = index == currentStep && currentStep < array.length;
            final isFound = array[index] == target && currentStep >= index;
            final isChecked = index < currentStep;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isFound
                    ? Colors.green
                    : isCurrent
                        ? Colors.orange
                        : isChecked
                            ? Colors.grey.shade400
                            : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent ? Colors.orange : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  '${array[index]}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (isCurrent || isFound) ? Colors.white : Colors.black,
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
              : currentStep < 6
                  ? 'Checking element at index $currentStep'
                  : 'Element found at index 6!',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
