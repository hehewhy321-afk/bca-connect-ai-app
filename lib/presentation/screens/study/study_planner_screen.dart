import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../data/models/study_models.dart';
import '../../../data/services/study_storage_service.dart';

// Providers
final studyStorageProvider = Provider((ref) => StudyStorageService());

final subjectsProvider = StateNotifierProvider<SubjectsNotifier, AsyncValue<List<Subject>>>((ref) {
  return SubjectsNotifier(ref.read(studyStorageProvider));
});

final schedulesProvider = StateNotifierProvider<SchedulesNotifier, AsyncValue<List<ClassSchedule>>>((ref) {
  return SchedulesNotifier(ref.read(studyStorageProvider));
});

final assignmentsProvider = StateNotifierProvider<AssignmentsNotifier, AsyncValue<List<Assignment>>>((ref) {
  return AssignmentsNotifier(ref.read(studyStorageProvider));
});

final examsProvider = StateNotifierProvider<ExamsNotifier, AsyncValue<List<Exam>>>((ref) {
  return ExamsNotifier(ref.read(studyStorageProvider));
});

final currentSemesterProvider = StateNotifierProvider<CurrentSemesterNotifier, int>((ref) {
  return CurrentSemesterNotifier(ref.read(studyStorageProvider));
});

// Notifiers
class SubjectsNotifier extends StateNotifier<AsyncValue<List<Subject>>> {
  final StudyStorageService _storage;

  SubjectsNotifier(this._storage) : super(const AsyncValue.loading()) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    state = const AsyncValue.loading();
    try {
      final subjects = await _storage.loadSubjects();
      state = AsyncValue.data(subjects);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSubject(Subject subject) async {
    final current = state.value ?? [];
    final updated = [...current, subject];
    await _storage.saveSubjects(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> updateSubject(Subject subject) async {
    final current = state.value ?? [];
    final updated = current.map((s) => s.id == subject.id ? subject : s).toList();
    await _storage.saveSubjects(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> deleteSubject(String id) async {
    final current = state.value ?? [];
    final updated = current.where((s) => s.id != id).toList();
    await _storage.saveSubjects(updated);
    state = AsyncValue.data(updated);
  }
}

class SchedulesNotifier extends StateNotifier<AsyncValue<List<ClassSchedule>>> {
  final StudyStorageService _storage;

  SchedulesNotifier(this._storage) : super(const AsyncValue.loading()) {
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    state = const AsyncValue.loading();
    try {
      final schedules = await _storage.loadSchedules();
      state = AsyncValue.data(schedules);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSchedule(ClassSchedule schedule) async {
    final current = state.value ?? [];
    final updated = [...current, schedule];
    await _storage.saveSchedules(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> deleteSchedule(String id) async {
    final current = state.value ?? [];
    final updated = current.where((s) => s.id != id).toList();
    await _storage.saveSchedules(updated);
    state = AsyncValue.data(updated);
  }
}

class AssignmentsNotifier extends StateNotifier<AsyncValue<List<Assignment>>> {
  final StudyStorageService _storage;

  AssignmentsNotifier(this._storage) : super(const AsyncValue.loading()) {
    loadAssignments();
  }

  Future<void> loadAssignments() async {
    state = const AsyncValue.loading();
    try {
      final assignments = await _storage.loadAssignments();
      state = AsyncValue.data(assignments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addAssignment(Assignment assignment) async {
    final current = state.value ?? [];
    final updated = [...current, assignment];
    await _storage.saveAssignments(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> updateAssignment(Assignment assignment) async {
    final current = state.value ?? [];
    final updated = current.map((a) => a.id == assignment.id ? assignment : a).toList();
    await _storage.saveAssignments(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> deleteAssignment(String id) async {
    final current = state.value ?? [];
    final updated = current.where((a) => a.id != id).toList();
    await _storage.saveAssignments(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> toggleComplete(String id) async {
    final current = state.value ?? [];
    final updated = current.map((a) {
      if (a.id == id) {
        return a.copyWith(isCompleted: !a.isCompleted);
      }
      return a;
    }).toList();
    await _storage.saveAssignments(updated);
    state = AsyncValue.data(updated);
  }
}

class ExamsNotifier extends StateNotifier<AsyncValue<List<Exam>>> {
  final StudyStorageService _storage;

  ExamsNotifier(this._storage) : super(const AsyncValue.loading()) {
    loadExams();
  }

  Future<void> loadExams() async {
    state = const AsyncValue.loading();
    try {
      final exams = await _storage.loadExams();
      state = AsyncValue.data(exams);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addExam(Exam exam) async {
    final current = state.value ?? [];
    final updated = [...current, exam];
    await _storage.saveExams(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> deleteExam(String id) async {
    final current = state.value ?? [];
    final updated = current.where((e) => e.id != id).toList();
    await _storage.saveExams(updated);
    state = AsyncValue.data(updated);
  }
}

class CurrentSemesterNotifier extends StateNotifier<int> {
  final StudyStorageService _storage;

  CurrentSemesterNotifier(this._storage) : super(1) {
    loadSemester();
  }

  Future<void> loadSemester() async {
    state = await _storage.getCurrentSemester();
  }

  Future<void> setSemester(int semester) async {
    await _storage.setCurrentSemester(semester);
    state = semester;
  }
}

// Main Screen
class StudyPlannerScreen extends ConsumerStatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  ConsumerState<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends ConsumerState<StudyPlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Iconsax.calendar_1), text: 'Timetable'),
            Tab(icon: Icon(Iconsax.task_square), text: 'Assignments'),
            Tab(icon: Icon(Iconsax.clipboard_text), text: 'Exams'),
            Tab(icon: Icon(Iconsax.book_1), text: 'Subjects'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TimetableTab(),
          AssignmentsTab(),
          ExamsTab(),
          SubjectsTab(),
        ],
      ),
    );
  }
}

// Timetable Tab
class TimetableTab extends ConsumerWidget {
  const TimetableTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(schedulesProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return schedulesAsync.when(
      data: (schedules) => subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.book_1, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No subjects added', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Add subjects first to create timetable', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            );
          }

          final subjectMap = {for (var s in subjects) s.id: s};
          final groupedSchedules = <DayOfWeek, List<ClassSchedule>>{};
          for (var schedule in schedules) {
            groupedSchedules.putIfAbsent(schedule.day, () => []).add(schedule);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: DayOfWeek.values.length,
                  itemBuilder: (context, index) {
                    final day = DayOfWeek.values[index];
                    final daySchedules = groupedSchedules[day] ?? [];
                    daySchedules.sort((a, b) => a.startTime.hour * 60 + a.startTime.minute - (b.startTime.hour * 60 + b.startTime.minute));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(day.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${daySchedules.length} classes'),
                        children: daySchedules.isEmpty
                            ? [const Padding(padding: EdgeInsets.all(16), child: Text('No classes', style: TextStyle(color: Colors.grey)))]
                            : daySchedules.map((schedule) {
                                final subject = subjectMap[schedule.subjectId];
                                return ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: subject?.color.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        subject?.code.substring(0, 2).toUpperCase() ?? '??',
                                        style: TextStyle(color: subject?.color, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  title: Text(subject?.name ?? 'Unknown'),
                                  subtitle: Text('${schedule.startTime.format(context)} - ${schedule.endTime.format(context)} • ${schedule.room}'),
                                  trailing: IconButton(
                                    icon: const Icon(Iconsax.trash, color: Colors.red),
                                    onPressed: () => ref.read(schedulesProvider.notifier).deleteSchedule(schedule.id),
                                  ),
                                );
                              }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

// Assignments Tab
class AssignmentsTab extends ConsumerWidget {
  const AssignmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return assignmentsAsync.when(
      data: (assignments) => subjectsAsync.when(
        data: (subjects) {
          final subjectMap = {for (var s in subjects) s.id: s};
          final sortedAssignments = [...assignments]..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          return Column(
            children: [
              Expanded(
                child: sortedAssignments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.task_square, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No assignments', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedAssignments.length,
                        itemBuilder: (context, index) {
                          final assignment = sortedAssignments[index];
                          final subject = subjectMap[assignment.subjectId];
                          final daysLeft = assignment.dueDate.difference(DateTime.now()).inDays;
                          final isOverdue = daysLeft < 0;
                          final isDueSoon = daysLeft >= 0 && daysLeft <= 3;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Checkbox(
                                value: assignment.isCompleted,
                                onChanged: (_) => ref.read(assignmentsProvider.notifier).toggleComplete(assignment.id),
                              ),
                              title: Text(
                                assignment.title,
                                style: TextStyle(
                                  decoration: assignment.isCompleted ? TextDecoration.lineThrough : null,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(subject?.name ?? 'Unknown Subject'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Iconsax.clock,
                                        size: 14,
                                        color: isOverdue ? Colors.red : (isDueSoon ? Colors.orange : Colors.grey),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(assignment.dueDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isOverdue ? Colors.red : (isDueSoon ? Colors.orange : Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!assignment.isCompleted)
                                        Text(
                                          isOverdue ? 'Overdue' : (isDueSoon ? '$daysLeft days left' : ''),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isOverdue ? Colors.red : Colors.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Iconsax.trash, color: Colors.red),
                                onPressed: () => ref.read(assignmentsProvider.notifier).deleteAssignment(assignment.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _showAddAssignmentDialog(context, ref, subjects),
                  icon: const Icon(Iconsax.add),
                  label: const Text('Add Assignment'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: const Color(0xFFDA7809),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  void _showAddAssignmentDialog(BuildContext context, WidgetRef ref, List<Subject> subjects) {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add subjects first')),
      );
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? selectedSubjectId = subjects.first.id;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                  items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) => setState(() => selectedSubjectId = val),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Due Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  trailing: const Icon(Iconsax.calendar),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (titleController.text.isEmpty || selectedSubjectId == null) return;
                final assignment = Assignment(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  subjectId: selectedSubjectId!,
                  title: titleController.text,
                  description: descController.text,
                  dueDate: selectedDate,
                );
                ref.read(assignmentsProvider.notifier).addAssignment(assignment);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// Exams Tab
class ExamsTab extends ConsumerWidget {
  const ExamsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return examsAsync.when(
      data: (exams) => subjectsAsync.when(
        data: (subjects) {
          final subjectMap = {for (var s in subjects) s.id: s};
          final sortedExams = [...exams]..sort((a, b) => a.dateTime.compareTo(b.dateTime));

          return Column(
            children: [
              Expanded(
                child: sortedExams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.clipboard_text, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No exams scheduled', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedExams.length,
                        itemBuilder: (context, index) {
                          final exam = sortedExams[index];
                          final subject = subjectMap[exam.subjectId];
                          final now = DateTime.now();
                          final daysLeft = exam.dateTime.difference(now).inDays;
                          final hoursLeft = exam.dateTime.difference(now).inHours;
                          final isPast = exam.dateTime.isBefore(now);

                          String countdown;
                          Color countdownColor;
                          if (isPast) {
                            countdown = 'Completed';
                            countdownColor = Colors.grey;
                          } else if (daysLeft == 0) {
                            countdown = hoursLeft > 0 ? '$hoursLeft hours left' : 'Today';
                            countdownColor = Colors.red;
                          } else if (daysLeft <= 7) {
                            countdown = '$daysLeft days left';
                            countdownColor = Colors.orange;
                          } else {
                            countdown = '$daysLeft days left';
                            countdownColor = Colors.green;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: subject?.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('MMM').format(exam.dateTime),
                                      style: TextStyle(fontSize: 10, color: subject?.color, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      DateFormat('dd').format(exam.dateTime),
                                      style: TextStyle(fontSize: 18, color: subject?.color, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(subject?.name ?? 'Unknown Subject'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Iconsax.clock, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('h:mm a').format(exam.dateTime),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Iconsax.location, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(exam.venue, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: countdownColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      countdown,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: countdownColor),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Iconsax.trash, color: Colors.red),
                                onPressed: () => ref.read(examsProvider.notifier).deleteExam(exam.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _showAddExamDialog(context, ref, subjects),
                  icon: const Icon(Iconsax.add),
                  label: const Text('Add Exam'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: const Color(0xFFDA7809),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  void _showAddExamDialog(BuildContext context, WidgetRef ref, List<Subject> subjects) {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add subjects first')),
      );
      return;
    }

    final titleController = TextEditingController();
    final venueController = TextEditingController();
    String? selectedSubjectId = subjects.first.id;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    String examType = 'Mid-term';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Exam'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                  items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) => setState(() => selectedSubjectId = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: examType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: ['Mid-term', 'Final', 'Quiz'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => examType = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: venueController,
                  decoration: const InputDecoration(labelText: 'Venue', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  trailing: const Icon(Iconsax.calendar),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                ),
                ListTile(
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: const Icon(Iconsax.clock),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: selectedTime);
                    if (time != null) setState(() => selectedTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (titleController.text.isEmpty || selectedSubjectId == null || venueController.text.isEmpty) return;
                final examDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                final exam = Exam(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  subjectId: selectedSubjectId!,
                  title: titleController.text,
                  dateTime: examDateTime,
                  venue: venueController.text,
                  duration: 180,
                  type: examType,
                );
                ref.read(examsProvider.notifier).addExam(exam);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// Subjects Tab
class SubjectsTab extends ConsumerWidget {
  const SubjectsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final currentSemester = ref.watch(currentSemesterProvider);

    return subjectsAsync.when(
      data: (subjects) {
        final semesterSubjects = subjects.where((s) => s.semester == currentSemester).toList();

        return Column(
          children: [
            // Semester Selector
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Semester:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(8, (index) {
                          final sem = index + 1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('Sem $sem'),
                              selected: currentSemester == sem,
                              onSelected: (_) => ref.read(currentSemesterProvider.notifier).setSemester(sem),
                              selectedColor: const Color(0xFFDA7809),
                              labelStyle: TextStyle(
                                color: currentSemester == sem ? Colors.white : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: semesterSubjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.book_1, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No subjects for Semester $currentSemester', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: semesterSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = semesterSubjects[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: subject.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  subject.code.substring(0, 2).toUpperCase(),
                                  style: TextStyle(
                                    color: subject.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Code: ${subject.code}'),
                                Text('Teacher: ${subject.teacher}'),
                                Text('Credits: ${subject.credits}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Iconsax.trash, color: Colors.red),
                              onPressed: () => ref.read(subjectsProvider.notifier).deleteSubject(subject.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _showAddSubjectDialog(context, ref, currentSemester),
                icon: const Icon(Iconsax.add),
                label: const Text('Add Subject'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(0xFFDA7809),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref, int semester) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final teacherController = TextEditingController();
    int credits = 3;
    Color selectedColor = Colors.blue;

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Subject Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Subject Code', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: teacherController,
                  decoration: const InputDecoration(labelText: 'Teacher Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: credits,
                  decoration: const InputDecoration(labelText: 'Credits', border: OutlineInputBorder()),
                  items: [1, 2, 3, 4, 5, 6].map((c) => DropdownMenuItem(value: c, child: Text('$c Credits'))).toList(),
                  onChanged: (val) => setState(() => credits = val!),
                ),
                const SizedBox(height: 12),
                const Text('Select Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colors.map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameController.text.isEmpty || codeController.text.isEmpty || teacherController.text.isEmpty) return;
                final subject = Subject(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  code: codeController.text,
                  teacher: teacherController.text,
                  color: selectedColor,
                  semester: semester,
                  credits: credits,
                );
                ref.read(subjectsProvider.notifier).addSubject(subject);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
