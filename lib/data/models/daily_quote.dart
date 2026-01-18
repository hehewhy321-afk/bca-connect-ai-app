class DailyQuote {
  final int id;
  final String text;
  final String category;
  final String icon;

  DailyQuote({
    required this.id,
    required this.text,
    required this.category,
    required this.icon,
  });

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      id: json['id'] as int,
      text: json['text'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'icon': icon,
    };
  }

  String get categoryLabel {
    switch (category) {
      case 'study_tip':
        return 'Study Tip';
      case 'exam_advice':
        return 'Exam Advice';
      case 'motivation':
        return 'Motivation';
      default:
        return 'Tip';
    }
  }
}
