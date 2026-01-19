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

  String _getStepExplanation() {
    switch (widget.algorithmId) {
      case 'bubble_sort':
        switch (_currentStep) {
          case 0: return '📊 Initial array: [64, 34, 25, 12, 22, 11, 90]\n💡 We will compare adjacent elements and swap if needed';
          case 1: return '🔄 Pass 1: Compare 64 & 34 → Swap! Now: [34, 64, 25...]\n✅ Largest element (90) bubbles to the end';
          case 2: return '🔄 Pass 2: Continue comparing pairs\n✅ Second largest element moves to correct position';
          case 3: return '🔄 Pass 3: Array getting more sorted\n💡 Notice how larger elements move right';
          case 4: return '🔄 Pass 4: Fewer comparisons needed now\n✅ More elements in correct positions';
          case 5: return '🔄 Pass 5: Almost sorted!\n💡 Only small elements need adjustment';
          case 6: return '🔄 Pass 6: Final comparisons\n✅ Array is nearly sorted';
          case 7: return '✅ Sorted! [11, 12, 22, 25, 34, 64, 90]\n🎉 All elements in ascending order';
          case 8: return '🎯 Complete! Time Complexity: O(n²)\n💡 Best for small datasets or nearly sorted arrays';
          default: return 'Watch the algorithm in action!';
        }
      
      case 'binary_search':
        switch (_currentStep) {
          case 0: return '🔍 Searching for 23 in: [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]\n💡 Array must be sorted for binary search';
          case 1: return '📍 Step 1: Check middle element (16)\n❌ 23 > 16, so search right half';
          case 2: return '📍 Step 2: New middle is 56\n❌ 23 < 56, so search left half';
          case 3: return '📍 Step 3: Middle is now 23\n✅ Found it! Target located';
          case 4: return '🎯 Success! Found 23 at index 5\n💡 Only took 3 comparisons instead of 6';
          case 5: return '⚡ Time Complexity: O(log n)\n💡 Much faster than linear search for large arrays';
          case 6: return '🎉 Binary search is efficient!\n💡 Divides search space in half each time';
          default: return 'Binary search in progress...';
        }
      
      case 'stack_push':
        switch (_currentStep) {
          case 0: return '📚 Empty stack (LIFO - Last In First Out)\n💡 Elements added/removed from top only';
          case 1: return '➕ Push 5 onto stack\n✅ Top = 5';
          case 2: return '➕ Push 10 onto stack\n✅ Top = 10 (5 is below)';
          case 3: return '➕ Push 15 onto stack\n✅ Top = 15';
          case 4: return '➕ Push 20 onto stack\n✅ Top = 20';
          case 5: return '🎯 Stack complete! [5, 10, 15, 20]\n💡 Used in: function calls, undo operations, expression evaluation';
          default: return 'Stack push operation...';
        }
      
      case 'queue_enqueue':
        switch (_currentStep) {
          case 0: return '🎫 Empty queue (FIFO - First In First Out)\n💡 Add at rear, remove from front';
          case 1: return '➕ Enqueue A\n✅ Front = A, Rear = A';
          case 2: return '➕ Enqueue B\n✅ Front = A, Rear = B';
          case 3: return '➕ Enqueue C\n✅ Front = A, Rear = C';
          case 4: return '➕ Enqueue D\n✅ Front = A, Rear = D';
          case 5: return '🎯 Queue complete! [A, B, C, D]\n💡 Used in: task scheduling, breadth-first search, printer queue';
          default: return 'Queue enqueue operation...';
        }
      
      case 'linked_list_insert':
        switch (_currentStep) {
          case 0: return '🔗 Original list: 10 → 20 → 30 → 40\n💡 We will insert 5 at the beginning';
          case 1: return '➕ Create new node with value 5\n💡 Allocate memory for new node';
          case 2: return '🔗 Link new node (5) to current head (10)\n✅ New node points to 10';
          case 3: return '✅ Update head to point to new node\n🎯 List is now: 5 → 10 → 20 → 30 → 40';
          case 4: return '🎉 Insert complete! Time: O(1)\n💡 Inserting at beginning is very fast in linked lists';
          default: return 'Linked list operation...';
        }
      
      case 'bfs':
        switch (_currentStep) {
          case 0: return '🗺️ BFS starts at node 0\n💡 Visit all neighbors before going deeper';
          case 1: return '✅ Visit node 0, add neighbors (1, 2) to queue\n📝 Queue: [1, 2]';
          case 2: return '✅ Visit node 1, add neighbors (3, 4) to queue\n📝 Queue: [2, 3, 4]';
          case 3: return '✅ Visit node 2, add neighbors (5, 6) to queue\n📝 Queue: [3, 4, 5, 6]';
          case 4: return '✅ Visit node 3\n📝 Queue: [4, 5, 6]';
          case 5: return '✅ Visit node 4\n📝 Queue: [5, 6]';
          case 6: return '✅ Visit nodes 5 and 6\n📝 Queue: []';
          case 7: return '🎯 BFS Complete! Order: 0→1→2→3→4→5→6\n💡 Used in: shortest path, social networks, web crawling';
          default: return 'BFS traversal...';
        }
      
      case 'dfs':
        switch (_currentStep) {
          case 0: return '🗺️ DFS starts at node 0\n💡 Go as deep as possible before backtracking';
          case 1: return '✅ Visit node 0, go to first neighbor (1)\n📝 Stack: [0]';
          case 2: return '✅ Visit node 1, go deeper to node 3\n📝 Stack: [0, 1]';
          case 3: return '✅ Visit node 3, no more children\n⬅️ Backtrack to node 1';
          case 4: return '✅ Visit node 4 from node 1\n⬅️ Backtrack to node 0';
          case 5: return '✅ Visit node 2 from node 0\n📝 Stack: [0, 2]';
          case 6: return '✅ Visit nodes 5 and 6\n⬅️ Backtrack complete';
          case 7: return '🎯 DFS Complete! Order: 0→1→3→4→2→5→6\n💡 Used in: maze solving, topological sort, cycle detection';
          default: return 'DFS traversal...';
        }
      
      case 'selection_sort':
        switch (_currentStep) {
          case 0: return '📊 Initial array: [29, 10, 14, 37, 13]\n💡 Find minimum and swap with first position';
          case 1: return '🔍 Pass 1: Find minimum (10), swap with position 0\n✅ [10, 29, 14, 37, 13]';
          case 2: return '🔍 Pass 2: Find minimum (13), swap with position 1\n✅ [10, 13, 14, 37, 29]';
          case 3: return '🔍 Pass 3: Minimum is 14, already in place\n✅ [10, 13, 14, 37, 29]';
          case 4: return '🔍 Pass 4: Find minimum (29), swap with position 3\n✅ [10, 13, 14, 29, 37]';
          case 5: return '✅ Sorted! [10, 13, 14, 29, 37]\n💡 Each pass selects the smallest element';
          case 6: return '🎯 Complete! Time: O(n²)\n💡 Good for small datasets, fewer swaps than bubble sort';
          case 7: return '💡 Selection sort makes minimum swaps\n✅ Only n-1 swaps for n elements';
          case 8: return '🎉 Algorithm mastered!\n💡 Used when memory writes are expensive';
          default: return 'Selection sort in progress...';
        }
      
      case 'insertion_sort':
        switch (_currentStep) {
          case 0: return '📊 Initial array: [12, 11, 13, 5, 6]\n💡 Build sorted array one element at a time';
          case 1: return '➡️ Element 11: Insert before 12\n✅ [11, 12, 13, 5, 6]';
          case 2: return '➡️ Element 13: Already in correct position\n✅ [11, 12, 13, 5, 6]';
          case 3: return '➡️ Element 5: Insert at beginning\n✅ [5, 11, 12, 13, 6]';
          case 4: return '➡️ Element 6: Insert after 5\n✅ [5, 6, 11, 12, 13]';
          case 5: return '✅ Sorted! [5, 6, 11, 12, 13]\n💡 Like sorting playing cards in your hand';
          case 6: return '🎯 Complete! Time: O(n²) worst, O(n) best\n💡 Efficient for nearly sorted arrays';
          case 7: return '💡 Insertion sort is adaptive\n✅ Fast when data is almost sorted';
          case 8: return '🎉 Algorithm mastered!\n💡 Used in: hybrid sorting, small datasets';
          default: return 'Insertion sort in progress...';
        }
      
      case 'merge_sort':
        switch (_currentStep) {
          case 0: return '📊 Initial: [38, 27, 43, 3, 9, 82, 10]\n💡 Divide and conquer strategy';
          case 1: return '✂️ Divide: Split into [38, 27, 43, 3] and [9, 82, 10]\n💡 Keep dividing until single elements';
          case 2: return '✂️ Further divide: [38, 27] [43, 3] [9, 82] [10]\n💡 Base case: arrays of size 1';
          case 3: return '🔀 Merge: [27, 38] and [3, 43]\n✅ Compare and merge sorted pairs';
          case 4: return '🔀 Merge: [3, 27, 38, 43]\n✅ Left half sorted';
          case 5: return '🔀 Merge: [9, 82] with [10]\n✅ Right half sorted: [9, 10, 82]';
          case 6: return '🔀 Final merge: Combine both halves\n✅ [3, 9, 10, 27, 38, 43, 82]';
          case 7: return '✅ Sorted! [3, 9, 10, 27, 38, 43, 82]\n🎯 Time: O(n log n) - guaranteed!';
          case 8: return '💡 Merge sort is stable and predictable\n✅ Used in: external sorting, linked lists';
          case 9: return '🎉 Divide and conquer mastered!\n💡 Always O(n log n), but needs extra space';
          case 10: return '🎯 Complete! Space: O(n)\n💡 Best for large datasets and linked lists';
          default: return 'Merge sort in progress...';
        }
      
      case 'quick_sort':
        switch (_currentStep) {
          case 0: return '📊 Initial: [10, 7, 8, 9, 1, 5]\n💡 Pick pivot and partition around it';
          case 1: return '🎯 Choose pivot: 5 (last element)\n💡 Partition: smaller left, larger right';
          case 2: return '↔️ Partition: [1] | 5 | [10, 7, 8, 9]\n✅ Pivot in correct position';
          case 3: return '🎯 Left: [1] already sorted\n🎯 Right: [10, 7, 8, 9] needs sorting';
          case 4: return '🎯 Right pivot: 9, partition again\n↔️ [7, 8] | 9 | [10]';
          case 5: return '🎯 Partition [7, 8]: pivot 8\n↔️ [7] | 8 | []';
          case 6: return '✅ All partitions sorted!\n🔀 Combine: [1, 5, 7, 8, 9, 10]';
          case 7: return '✅ Sorted! [1, 5, 7, 8, 9, 10]\n🎯 Average time: O(n log n)';
          case 8: return '💡 Quick sort is in-place\n✅ No extra space needed (unlike merge sort)';
          case 9: return '🎉 Partitioning mastered!\n💡 Used in: most standard libraries, general sorting';
          case 10: return '🎯 Complete! Space: O(log n)\n💡 Fastest in practice, but O(n²) worst case';
          default: return 'Quick sort in progress...';
        }
      
      case 'heap_sort':
        switch (_currentStep) {
          case 0: return '📊 Initial: [4, 10, 3, 5, 1]\n💡 Build max heap, then extract elements';
          case 1: return '🏗️ Build max heap: [10, 5, 3, 4, 1]\n✅ Parent ≥ children property satisfied';
          case 2: return '🔄 Swap root (10) with last, heapify\n✅ [5, 4, 3, 1] | 10';
          case 3: return '🔄 Swap root (5) with last, heapify\n✅ [4, 1, 3] | 5, 10';
          case 4: return '🔄 Swap root (4) with last, heapify\n✅ [3, 1] | 4, 5, 10';
          case 5: return '🔄 Swap root (3) with last\n✅ [1] | 3, 4, 5, 10';
          case 6: return '✅ Sorted! [1, 3, 4, 5, 10]\n🎯 Time: O(n log n) guaranteed';
          case 7: return '💡 Heap sort is in-place\n✅ No extra space, always O(n log n)';
          case 8: return '🎉 Heap structure mastered!\n💡 Used in: priority queues, k largest elements';
          case 9: return '🎯 Complete! Space: O(1)\n💡 Not stable, but memory efficient';
          case 10: return '💡 Heap property: parent ≥ children\n✅ Foundation for priority queues';
          default: return 'Heap sort in progress...';
        }
      
      case 'counting_sort':
        switch (_currentStep) {
          case 0: return '📊 Initial: [1, 4, 1, 2, 7, 5, 2]\n💡 Count frequency of each element';
          case 1: return '📝 Count array: 0:[0] 1:[2] 2:[2] 4:[1] 5:[1] 7:[1]\n✅ Frequency of each number';
          case 2: return '➕ Cumulative count: 1:[2] 2:[4] 4:[5] 5:[6] 7:[7]\n💡 Positions in sorted array';
          case 3: return '📍 Place elements using counts\n✅ [1, 1, 2, 2, 4, 5, 7]';
          case 4: return '✅ Sorted! [1, 1, 2, 2, 4, 5, 7]\n🎯 Time: O(n + k) where k is range';
          case 5: return '💡 Counting sort is stable\n✅ Preserves relative order of equal elements';
          case 6: return '🎉 Non-comparison sort mastered!\n💡 Used in: radix sort, small integer ranges';
          default: return 'Counting sort in progress...';
        }
      
      case 'linear_search':
        switch (_currentStep) {
          case 0: return '🔍 Searching for 31 in: [10, 23, 45, 70, 11, 15, 31, 89]\n💡 Check each element one by one';
          case 1: return '❌ Check index 0: 10 ≠ 31\n➡️ Move to next element';
          case 2: return '❌ Check index 1: 23 ≠ 31\n➡️ Continue searching';
          case 3: return '❌ Check indices 2-5: Not found\n➡️ Keep going...';
          case 4: return '✅ Check index 6: 31 = 31\n🎯 Found at position 6!';
          case 5: return '🎉 Search complete! Found 31\n⏱️ Time: O(n) - checked 7 elements';
          case 6: return '💡 Linear search works on unsorted data\n✅ Used in: small arrays, unsorted data';
          default: return 'Linear search in progress...';
        }
      
      case 'stack_pop':
        switch (_currentStep) {
          case 0: return '📚 Stack: [5, 10, 15, 20] (Top = 20)\n💡 Remove from top (LIFO)';
          case 1: return '➖ Pop 20 from stack\n✅ Top = 15, Stack: [5, 10, 15]';
          case 2: return '➖ Pop 15 from stack\n✅ Top = 10, Stack: [5, 10]';
          case 3: return '✅ Stack after 2 pops: [5, 10]\n💡 Top element is now 10';
          case 4: return '🎯 Pop operations complete!\n⏱️ Time: O(1) per operation';
          case 5: return '💡 Stack pop is constant time\n✅ Used in: undo operations, backtracking, expression evaluation';
          default: return 'Stack pop operation...';
        }
      
      case 'queue_dequeue':
        switch (_currentStep) {
          case 0: return '🎫 Queue: [A, B, C, D] (Front = A)\n💡 Remove from front (FIFO)';
          case 1: return '➖ Dequeue A from front\n✅ Front = B, Queue: [B, C, D]';
          case 2: return '➖ Dequeue B from front\n✅ Front = C, Queue: [C, D]';
          case 3: return '✅ Queue after 2 dequeues: [C, D]\n💡 Front element is now C';
          case 4: return '🎯 Dequeue operations complete!\n⏱️ Time: O(1) per operation';
          case 5: return '💡 Queue dequeue is constant time\n✅ Used in: task scheduling, BFS, print spooling';
          default: return 'Queue dequeue operation...';
        }
      
      case 'circular_queue':
        switch (_currentStep) {
          case 0: return '🔄 Circular Queue (size 5): Empty\n💡 Front and rear wrap around';
          case 1: return '➕ Enqueue A, B, C\n✅ Queue: [A, B, C, _, _]';
          case 2: return '➖ Dequeue A, B\n✅ Queue: [_, _, C, _, _]';
          case 3: return '➕ Enqueue D, E, F (wraps around)\n✅ Queue: [E, F, C, D, _]';
          case 4: return '🔄 Rear wrapped to beginning!\n💡 Efficient use of space';
          case 5: return '🎯 Circular queue complete!\n✅ Used in: buffering, resource allocation';
          default: return 'Circular queue operation...';
        }
      
      case 'bst_insert':
        switch (_currentStep) {
          case 0: return '🌳 Insert into BST: [50, 30, 70, 20, 40, 60, 80]\n💡 Left < Parent < Right';
          case 1: return '➕ Insert 50 as root\n✅ Tree: [50]';
          case 2: return '➕ Insert 30 (< 50, go left)\n✅ Tree: 50 → 30';
          case 3: return '➕ Insert 70 (> 50, go right)\n✅ Tree: 50 → [30, 70]';
          case 4: return '➕ Insert 20, 40 under 30\n✅ Left subtree complete';
          case 5: return '➕ Insert 60, 80 under 70\n✅ Right subtree complete';
          case 6: return '🎯 BST complete! Height-balanced\n⏱️ Search time: O(log n) average';
          default: return 'BST insert operation...';
        }
      
      case 'avl_rotation':
        switch (_currentStep) {
          case 0: return '🌳 Insert [10, 20, 30] into AVL tree\n💡 Self-balancing BST';
          case 1: return '➕ Insert 10 as root\n✅ Tree: [10], Balance: 0';
          case 2: return '➕ Insert 20 (right child)\n✅ Tree: 10 → 20, Balance: -1';
          case 3: return '➕ Insert 30 (right-right case)\n⚠️ Unbalanced! Balance: -2';
          case 4: return '🔄 Left rotation at 10\n✅ New root: 20, Tree: 20 → [10, 30]';
          case 5: return '🎯 AVL tree balanced!\n✅ All nodes have balance factor ∈ {-1, 0, 1}';
          default: return 'AVL rotation operation...';
        }
      
      case 'dijkstra':
        switch (_currentStep) {
          case 0: return '🗺️ Find shortest path from A to E\n💡 Greedy algorithm with priority queue';
          case 1: return '📍 Start at A, distance = 0\n✅ Mark A as visited';
          case 2: return '🔍 Update neighbors of A\n✅ B: 4, C: 2';
          case 3: return '📍 Visit C (smallest distance: 2)\n✅ Update D: 2+3=5, E: 2+8=10';
          case 4: return '📍 Visit B (distance: 4)\n✅ Update D: min(5, 4+1)=5';
          case 5: return '📍 Visit D (distance: 5)\n✅ Update E: min(10, 5+2)=7';
          case 6: return '📍 Visit E (distance: 7)\n✅ Shortest path found!';
          case 7: return '🎯 Path: A → C → D → E\n✅ Total distance: 7';
          case 8: return '💡 Dijkstra guarantees shortest path\n⏱️ Time: O((V+E) log V) with heap';
          default: return 'Dijkstra algorithm in progress...';
        }
      
      case 'kruskal':
        switch (_currentStep) {
          case 0: return '🗺️ Find Minimum Spanning Tree\n💡 Connect all nodes with minimum total weight';
          case 1: return '📊 Sort edges by weight\n✅ [(A-B, 1), (B-C, 2), (A-C, 3), ...]';
          case 2: return '➕ Add edge A-B (weight: 1)\n✅ No cycle formed';
          case 3: return '➕ Add edge B-C (weight: 2)\n✅ No cycle formed';
          case 4: return '❌ Skip edge A-C (would create cycle)\n💡 Union-Find detects cycles';
          case 5: return '➕ Add edge C-D (weight: 4)\n✅ Tree growing...';
          case 6: return '➕ Add edge D-E (weight: 5)\n✅ All nodes connected!';
          case 7: return '🎯 MST complete! Total weight: 12\n💡 Used in: network design, clustering';
          default: return 'Kruskal algorithm in progress...';
        }
      
      case 'topological_sort':
        switch (_currentStep) {
          case 0: return '🗺️ Order tasks: A→B, B→C, A→D\n💡 Dependencies must come first';
          case 1: return '📊 Calculate in-degrees\n✅ A:0, B:1, C:1, D:1';
          case 2: return '➡️ Start with A (in-degree 0)\n✅ Order: [A]';
          case 3: return '➡️ Remove A, update in-degrees\n✅ B:0, D:0 now available';
          case 4: return '➡️ Add B to order\n✅ Order: [A, B]';
          case 5: return '➡️ Add D and C\n✅ Order: [A, B, D, C]';
          case 6: return '🎯 Topological order complete!\n💡 Used in: build systems, course scheduling';
          default: return 'Topological sort in progress...';
        }
      
      default:
        return _currentStep == 0
            ? 'Watch the algorithm solve the example step by step'
            : 'Step $_currentStep: Algorithm in progress...';
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
        // Step Explanation Panel
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFDA7809).withValues(alpha: 0.1),
                const Color(0xFFFF9500).withValues(alpha: 0.05),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFDA7809).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDA7809).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      size: 16,
                      color: Color(0xFFDA7809),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Step Explanation',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getStepExplanation(),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
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
