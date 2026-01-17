import 'package:flutter/material.dart';

enum TransactionType { income, expense }

enum TransactionCategory {
  // Income categories
  salary,
  freelance,
  investment,
  gift,
  otherIncome,
  
  // Expense categories
  food,
  transport,
  shopping,
  bills,
  entertainment,
  health,
  education,
  rent,
  otherExpense,
}

extension TransactionCategoryExtension on TransactionCategory {
  String get displayName {
    switch (this) {
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.freelance:
        return 'Freelance';
      case TransactionCategory.investment:
        return 'Investment';
      case TransactionCategory.gift:
        return 'Gift';
      case TransactionCategory.otherIncome:
        return 'Other Income';
      case TransactionCategory.food:
        return 'Food & Dining';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.bills:
        return 'Bills & Utilities';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.health:
        return 'Health';
      case TransactionCategory.education:
        return 'Education';
      case TransactionCategory.rent:
        return 'Rent';
      case TransactionCategory.otherExpense:
        return 'Other Expense';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionCategory.salary:
        return Icons.account_balance_wallet;
      case TransactionCategory.freelance:
        return Icons.work;
      case TransactionCategory.investment:
        return Icons.trending_up;
      case TransactionCategory.gift:
        return Icons.card_giftcard;
      case TransactionCategory.otherIncome:
        return Icons.attach_money;
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.transport:
        return Icons.directions_car;
      case TransactionCategory.shopping:
        return Icons.shopping_bag;
      case TransactionCategory.bills:
        return Icons.receipt_long;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.health:
        return Icons.local_hospital;
      case TransactionCategory.education:
        return Icons.school;
      case TransactionCategory.rent:
        return Icons.home;
      case TransactionCategory.otherExpense:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case TransactionCategory.salary:
      case TransactionCategory.freelance:
      case TransactionCategory.investment:
      case TransactionCategory.gift:
      case TransactionCategory.otherIncome:
        return Colors.green;
      case TransactionCategory.food:
        return Colors.orange;
      case TransactionCategory.transport:
        return Colors.blue;
      case TransactionCategory.shopping:
        return Colors.purple;
      case TransactionCategory.bills:
        return Colors.red;
      case TransactionCategory.entertainment:
        return Colors.pink;
      case TransactionCategory.health:
        return Colors.teal;
      case TransactionCategory.education:
        return Colors.indigo;
      case TransactionCategory.rent:
        return Colors.brown;
      case TransactionCategory.otherExpense:
        return Colors.grey;
    }
  }

  static List<TransactionCategory> getByType(TransactionType type) {
    if (type == TransactionType.income) {
      return [
        TransactionCategory.salary,
        TransactionCategory.freelance,
        TransactionCategory.investment,
        TransactionCategory.gift,
        TransactionCategory.otherIncome,
      ];
    } else {
      return [
        TransactionCategory.food,
        TransactionCategory.transport,
        TransactionCategory.shopping,
        TransactionCategory.bills,
        TransactionCategory.entertainment,
        TransactionCategory.health,
        TransactionCategory.education,
        TransactionCategory.rent,
        TransactionCategory.otherExpense,
      ];
    }
  }
}

class FinanceTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
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
      'category': category.name,
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
      category: TransactionCategory.values.firstWhere((e) => e.name == json['category']),
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  FinanceTransaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
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
