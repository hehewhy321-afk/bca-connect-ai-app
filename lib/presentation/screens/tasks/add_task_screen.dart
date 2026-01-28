import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/models/task.dart';
import '../../providers/task_provider.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final Task? task; // For editing existing tasks

  const AddTaskScreen({super.key, this.task});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskStatus _selectedStatus = TaskStatus.pending;
  String? _selectedCategoryId;
  DateTime? _selectedDueDate;
  DateTime? _selectedReminderDate;
  List<String> _tags = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    // If editing, populate fields
    if (widget.task != null) {
      final task = widget.task!;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _selectedPriority = task.priority;
      _selectedStatus = task.status;
      _selectedCategoryId = task.categoryId;
      _selectedDueDate = task.dueDate;
      _selectedReminderDate = task.reminderDate;
      _tags = List.from(task.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(taskCategoriesProvider);
    final isEditing = widget.task != null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context, isEditing),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleField(),
              const SizedBox(height: 24),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              _buildPrioritySection(),
              const SizedBox(height: 24),
              if (isEditing) ...[
                _buildStatusSection(),
                const SizedBox(height: 24),
              ],
              _buildCategorySection(categoriesAsync),
              const SizedBox(height: 24),
              _buildDueDateSection(),
              const SizedBox(height: 24),
              _buildReminderSection(),
              const SizedBox(height: 24),
              _buildTagsSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isEditing) {
    return AppBar(
      title: Text(isEditing ? 'Edit Task' : 'Add New Task'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          TextButton(
            onPressed: _saveTask,
            child: Text(
              isEditing ? 'Update' : 'Save',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: ModernTheme.primaryOrange,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Task Title'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: _buildInputDecoration(
            hintText: 'Enter task title...',
            prefixIcon: const Icon(Iconsax.edit),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a task title';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Description (Optional)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: _buildInputDecoration(
            hintText: 'Add task description...',
            prefixIcon: const Icon(Iconsax.document_text),
          ),
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Priority'),
        const SizedBox(height: 8),
        _buildPrioritySelector(),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Status'),
        const SizedBox(height: 8),
        _buildStatusSelector(),
      ],
    );
  }

  Widget _buildCategorySection(AsyncValue<List<TaskCategory>> categoriesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Category'),
        const SizedBox(height: 8),
        categoriesAsync.when(
          data: (categories) => _buildCategorySelector(categories),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorWidget('Error loading categories: $error'),
        ),
      ],
    );
  }

  Widget _buildDueDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Due Date (Optional)'),
        const SizedBox(height: 8),
        _buildDateSelector(
          'Select due date',
          _selectedDueDate,
          (date) => setState(() => _selectedDueDate = date),
          Iconsax.calendar,
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Reminder (Optional)'),
        const SizedBox(height: 8),
        _buildDateSelector(
          'Set reminder',
          _selectedReminderDate,
          (date) => setState(() => _selectedReminderDate = date),
          Iconsax.notification,
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.danger, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required Widget prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildPrioritySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: TaskPriority.values.map((priority) {
          final isSelected = _selectedPriority == priority;
          return InkWell(
            onTap: () => setState(() => _selectedPriority = priority),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? priority.color.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    priority.icon,
                    color: priority.color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    priority.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? priority.color : null,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Iconsax.tick_circle,
                      color: priority.color,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: TaskStatus.values.map((status) {
          final isSelected = _selectedStatus == status;
          return InkWell(
            onTap: () => setState(() => _selectedStatus = status),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? status.color.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    status.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? status.color : null,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Iconsax.tick_circle,
                      color: status.color,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategorySelector(List<TaskCategory> categories) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // None option
          InkWell(
            onTap: () => setState(() => _selectedCategoryId = null),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedCategoryId == null 
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) 
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.close_circle, size: 20),
                  const SizedBox(width: 12),
                  const Text('No Category'),
                  const Spacer(),
                  if (_selectedCategoryId == null)
                    Icon(
                      Iconsax.tick_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          // Category options
          ...categories.map((category) {
            final isSelected = _selectedCategoryId == category.id;
            return InkWell(
              onTap: () => setState(() => _selectedCategoryId = category.id),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? category.color.withValues(alpha: 0.1) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      category.icon,
                      color: category.color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? category.color : null,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Iconsax.tick_circle,
                        color: category.color,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
    String hint,
    DateTime? selectedDate,
    Function(DateTime?) onDateSelected,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => _selectDate(selectedDate, onDateSelected),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate != null
                    ? DateFormat('MMM d, y • h:mm a').format(selectedDate)
                    : hint,
                style: TextStyle(
                  color: selectedDate != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (selectedDate != null)
              GestureDetector(
                onTap: () => onDateSelected(null),
                child: Icon(
                  Iconsax.close_circle,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add tag field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add a tag...',
                  prefixIcon: const Icon(Iconsax.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _addTag(_tagController.text),
              icon: const Icon(Iconsax.add),
              style: IconButton.styleFrom(
                backgroundColor: ModernTheme.primaryOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Tags display
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Iconsax.close_circle, size: 16),
                onDeleted: () => _removeTag(tag),
                backgroundColor: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: ModernTheme.primaryOrange),
                deleteIconColor: ModernTheme.primaryOrange,
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _selectDate(DateTime? currentDate, Function(DateTime?) onDateSelected) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDate ?? DateTime.now()),
      );

      if (time != null && mounted) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onDateSelected(selectedDateTime);
      }
    }
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        priority: _selectedPriority,
        status: _selectedStatus,
        categoryId: _selectedCategoryId,
        dueDate: _selectedDueDate,
        reminderDate: _selectedReminderDate,
        tags: _tags,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        completedAt: _selectedStatus == TaskStatus.completed 
            ? (widget.task?.completedAt ?? DateTime.now())
            : null,
      );

      if (widget.task != null) {
        await ref.read(taskProvider.notifier).updateTask(task);
      } else {
        await ref.read(taskProvider.notifier).addTask(task);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.task != null 
                ? 'Task updated successfully!' 
                : 'Task created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}