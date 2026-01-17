import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_models.dart';

class StudyStorageService {
  static const String _subjectsKey = 'study_subjects';
  static const String _schedulesKey = 'study_schedules';
  static const String _assignmentsKey = 'study_assignments';
  static const String _examsKey = 'study_exams';
  static const String _sessionsKey = 'study_sessions';
  static const String _currentSemesterKey = 'current_semester';

  // Subjects
  Future<List<Subject>> loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_subjectsKey);
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Subject.fromJson(json)).toList();
  }

  Future<void> saveSubjects(List<Subject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = subjects.map((s) => s.toJson()).toList();
    await prefs.setString(_subjectsKey, jsonEncode(jsonList));
  }

  // Schedules
  Future<List<ClassSchedule>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_schedulesKey);
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => ClassSchedule.fromJson(json)).toList();
  }

  Future<void> saveSchedules(List<ClassSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = schedules.map((s) => s.toJson()).toList();
    await prefs.setString(_schedulesKey, jsonEncode(jsonList));
  }

  // Assignments
  Future<List<Assignment>> loadAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_assignmentsKey);
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Assignment.fromJson(json)).toList();
  }

  Future<void> saveAssignments(List<Assignment> assignments) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = assignments.map((a) => a.toJson()).toList();
    await prefs.setString(_assignmentsKey, jsonEncode(jsonList));
  }

  // Exams
  Future<List<Exam>> loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_examsKey);
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Exam.fromJson(json)).toList();
  }

  Future<void> saveExams(List<Exam> exams) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = exams.map((e) => e.toJson()).toList();
    await prefs.setString(_examsKey, jsonEncode(jsonList));
  }

  // Study Sessions
  Future<List<StudySession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_sessionsKey);
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => StudySession.fromJson(json)).toList();
  }

  Future<void> saveSessions(List<StudySession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_sessionsKey, jsonEncode(jsonList));
  }

  // Current Semester
  Future<int> getCurrentSemester() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentSemesterKey) ?? 1;
  }

  Future<void> setCurrentSemester(int semester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentSemesterKey, semester);
  }

  // Clear all data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subjectsKey);
    await prefs.remove(_schedulesKey);
    await prefs.remove(_assignmentsKey);
    await prefs.remove(_examsKey);
    await prefs.remove(_sessionsKey);
  }
}
