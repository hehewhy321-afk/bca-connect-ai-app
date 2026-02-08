import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../../core/theme/modern_theme.dart';

class TaskFilterDialog extends ConsumerStatefulWidget {
  const TaskFilterDialog({super.key});

  @override
  ConsumerState<TaskFilterDialog> createState() => _TaskFilterDialogState();
}

class _TaskFilterDialogState extends ConsumerState<TaskFilterDialog> {
  late TaskFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = ref.read(taskFilterProvider);
  }

  void _applyFilter() {
    ref.read(taskFilterProvider.notifier).state = _currentFilter;
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _currentFilter = TaskFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(taskCategoriesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Sort By'),
                  _buildSortOptions(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Status'),
                  _buildStatusOptions(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Priority'),
                  _buildPriorityOptions(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Category'),
                  _buildCategoryOptions(categoriesAsync),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Other'),
                  _buildDateToggles(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filter Tasks',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: _clearAll, child: const Text('Clear All')),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return Wrap(
      spacing: 8,
      children: TaskSortBy.values.map((sort) {
        final isSelected = _currentFilter.sortBy == sort;
        return ChoiceChip(
          label: Text(_getSortName(sort)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(
                () => _currentFilter = _currentFilter.copyWith(sortBy: sort),
              );
            }
          },
        );
      }).toList(),
    );
  }

  String _getSortName(TaskSortBy sort) {
    switch (sort) {
      case TaskSortBy.dueDate:
        return 'Due Date';
      case TaskSortBy.priority:
        return 'Priority';
      case TaskSortBy.title:
        return 'Title';
      case TaskSortBy.createdDate:
        return 'Created Date';
    }
  }

  Widget _buildStatusOptions() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: _currentFilter.status == null,
          onSelected: (selected) {
            if (selected) {
              setState(
                () => _currentFilter = _currentFilter.copyWith(status: null),
              );
            }
          },
        ),
        ...TaskStatus.values.map((status) {
          final isSelected = _currentFilter.status == status;
          return ChoiceChip(
            label: Text(status.displayName),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(
                  () =>
                      _currentFilter = _currentFilter.copyWith(status: status),
                );
              }
            },
          );
        }),
      ],
    );
  }

  Widget _buildPriorityOptions() {
    return Wrap(
      spacing: 8,
      children: TaskPriority.values.map((priority) {
        final isSelected = _currentFilter.priority == priority;
        return ChoiceChip(
          label: Text(priority.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _currentFilter = _currentFilter.copyWith(
                priority: selected ? priority : null,
              );
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCategoryOptions(AsyncValue<List<TaskCategory>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) => Wrap(
        spacing: 8,
        children: categories.map((cat) {
          final isSelected = _currentFilter.categoryId == cat.id;
          return ChoiceChip(
            label: Text(cat.name),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  categoryId: selected ? cat.id : null,
                );
              });
            },
          );
        }).toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Error loading categories'),
    );
  }

  Widget _buildDateToggles() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Overdue Only'),
          value: _currentFilter.showOverdueOnly,
          onChanged: (val) {
            setState(
              () => _currentFilter = _currentFilter.copyWith(
                showOverdueOnly: val,
              ),
            );
          },
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Due Today Only'),
          value: _currentFilter.showDueTodayOnly,
          onChanged: (val) {
            setState(
              () => _currentFilter = _currentFilter.copyWith(
                showDueTodayOnly: val,
              ),
            );
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _applyFilter,
        style: ElevatedButton.styleFrom(
          backgroundColor: ModernTheme.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Apply Filter',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
