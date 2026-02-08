import 'package:flutter/material.dart';

enum TransactionType { income, expense }

class FinanceCategory {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final TransactionType type;
  final bool isDefault;

  FinanceCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.type,
    this.isDefault = false,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'type': type.name,
      'isDefault': isDefault,
    };
  }

  factory FinanceCategory.fromJson(Map<String, dynamic> json) {
    return FinanceCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinanceCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Default Categories
  static List<FinanceCategory> defaultCategories = [
    // Income
    FinanceCategory(
      id: 'salary',
      name: 'Salary',
      iconCodePoint: Icons.account_balance_wallet.codePoint,
      colorValue: Colors.green.toARGB32(),
      type: TransactionType.income,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'freelance',
      name: 'Freelance',
      iconCodePoint: Icons.work.codePoint,
      colorValue: Colors.green.toARGB32(),
      type: TransactionType.income,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'investment',
      name: 'Investment',
      iconCodePoint: Icons.trending_up.codePoint,
      colorValue: Colors.green.toARGB32(),
      type: TransactionType.income,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'gift',
      name: 'Gift',
      iconCodePoint: Icons.card_giftcard.codePoint,
      colorValue: Colors.green.toARGB32(),
      type: TransactionType.income,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'other_income',
      name: 'Other Income',
      iconCodePoint: Icons.attach_money.codePoint,
      colorValue: Colors.green.toARGB32(),
      type: TransactionType.income,
      isDefault: true,
    ),
    // Expense
    FinanceCategory(
      id: 'food',
      name: 'Food & Dining',
      iconCodePoint: Icons.restaurant.codePoint,
      colorValue: Colors.orange.toARGB32(),
      type: TransactionType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'transport',
      name: 'Transport',
      iconCodePoint: Icons.directions_car.codePoint,
      colorValue: Colors.blue.toARGB32(),
      type: TransactionType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'shopping',
      name: 'Shopping',
      iconCodePoint: Icons.shopping_bag.codePoint,
      colorValue: Colors.purple.toARGB32(),
      type: TransactionType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'bills',
      name: 'Bills & Utilities',
      iconCodePoint: Icons.receipt_long.codePoint,
      colorValue: Colors.red.toARGB32(),
      type: TransactionType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'entertainment',
      name: 'Entertainment',
      iconCodePoint: Icons.movie.codePoint,
      colorValue: Colors.pink.toARGB32(),
      type: TransactionType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'health',
      name: 'Health',
      iconCodePoint: Icons.local_hospital.codePoint,
      colorValue: Colors.teal.toARGB32(),
      type: TransactionType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'education',
      name: 'Education',
      iconCodePoint: Icons.school.codePoint,
      colorValue: Colors.indigo.toARGB32(),
      type: TransactionType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'rent',
      name: 'Rent',
      iconCodePoint: Icons.home.codePoint,
      colorValue: Colors.brown.toARGB32(),
      type: TransactionType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'other_expense',
      name: 'Other Expense',
      iconCodePoint: Icons.more_horiz.codePoint,
      colorValue: Colors.grey.toARGB32(),
      type: TransactionType.expense,
      isDefault: true,
    ),
  ];
}

class FinanceTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final FinanceCategory category;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  FinanceTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'category': category.toJson(),
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) {
    return FinanceTransaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      category: FinanceCategory.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  FinanceTransaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    FinanceCategory? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
