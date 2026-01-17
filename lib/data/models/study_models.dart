import 'package:flutter/material.dart';

// Days of week
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  String get shortName => displayName.substring(0, 3);
}

// Subject/Class
class Subject {
  final String id;
  final String name;
  final String code;
  final String teacher;
  final Color color;
  final int semester;
  final int credits;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.teacher,
    required this.color,
    required this.semester,
    required this.credits,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'teacher': teacher,
      'color': color.value.toRadixString(16).padLeft(8, '0'),
      'semester': semester,
      'credits': credits,
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    final colorValue = json['color'];
    final color = colorValue is String 
        ? Color(int.parse(colorValue, radix: 16))
        : Color(colorValue as int);
    
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      teacher: json['teacher'] as String,
      color: color,
      semester: json['semester'] as int,
      credits: json['credits'] as int,
    );
  }
}

// Class Schedule (Timetable Entry)
class ClassSchedule {
  final String id;
  final String subjectId;
  final DayOfWeek day;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String room;
  final String type; // Lecture, Lab, Tutorial

  ClassSchedule({
    required this.id,
    required this.subjectId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'day': day.name,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'room': room,
      'type': type,
    };
  }

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    final startParts = (json['startTime'] as String).split(':');
    final endParts = (json['endTime'] as String).split(':');
    
    return ClassSchedule(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      day: DayOfWeek.values.firstWhere((e) => e.name == json['day']),
      startTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      room: json['room'] as String,
      type: json['type'] as String,
    );
  }
}

// Assignment
class Assignment {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final int priority; // 1-3 (High, Medium, Low)

  Assignment({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = 2,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'priority': priority,
    };
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: json['priority'] as int? ?? 2,
    );
  }

  Assignment copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    int? priority,
  }) {
    return Assignment(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
    );
  }
}

// Exam
class Exam {
  final String id;
  final String subjectId;
  final String title;
  final DateTime dateTime;
  final String venue;
  final int duration; // in minutes
  final String type; // Mid-term, Final, Quiz

  Exam({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.dateTime,
    required this.venue,
    required this.duration,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'venue': venue,
      'duration': duration,
      'type': type,
    };
  }

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      venue: json['venue'] as String,
      duration: json['duration'] as int,
      type: json['type'] as String,
    );
  }
}

// Study Session
class StudySession {
  final String id;
  final String subjectId;
  final DateTime startTime;
  final DateTime endTime;
  final String notes;
  final int focusRating; // 1-5

  StudySession({
    required this.id,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    this.notes = '',
    this.focusRating = 3,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'notes': notes,
      'focusRating': focusRating,
    };
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      notes: json['notes'] as String? ?? '',
      focusRating: json['focusRating'] as int? ?? 3,
    );
  }
}
