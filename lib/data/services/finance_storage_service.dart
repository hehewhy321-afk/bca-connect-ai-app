import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance_transaction.dart';

class FinanceStorageService {
  static const String _transactionsKey = 'finance_transactions';
  static const String _budgetKey = 'finance_budget';
  static const String _categoriesKey = 'finance_categories';

  // Save transactions
  Future<void> saveTransactions(List<FinanceTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_transactionsKey, jsonEncode(jsonList));
  }

  // Load transactions
  Future<List<FinanceTransaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_transactionsKey);

    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => FinanceTransaction.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Add transaction
  Future<void> addTransaction(FinanceTransaction transaction) async {
    final transactions = await loadTransactions();
    transactions.add(transaction);
    await saveTransactions(transactions);
  }

  // Update transaction
  Future<void> updateTransaction(FinanceTransaction transaction) async {
    final transactions = await loadTransactions();
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
      await saveTransactions(transactions);
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    final transactions = await loadTransactions();
    transactions.removeWhere((t) => t.id == id);
    await saveTransactions(transactions);
  }

  // Clear all transactions
  Future<void> clearAllTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transactionsKey);
  }

  // Categories management
  Future<void> saveCategories(List<FinanceCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final customCategories = categories.where((c) => !c.isDefault).toList();
    final jsonList = customCategories.map((c) => c.toJson()).toList();
    await prefs.setString(_categoriesKey, jsonEncode(jsonList));
  }

  Future<List<FinanceCategory>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_categoriesKey);

    final List<FinanceCategory> categories = List.from(
      FinanceCategory.defaultCategories,
    );

    if (jsonString != null) {
      try {
        final jsonList = jsonDecode(jsonString) as List;
        final customCategories = jsonList
            .map((json) => FinanceCategory.fromJson(json))
            .toList();
        categories.addAll(customCategories);
      } catch (e) {
        // Fallback to defaults
      }
    }

    return categories;
  }

  // Export to JSON
  Future<String> exportToJson() async {
    final transactions = await loadTransactions();
    final categories = await loadCategories();
    final customCategories = categories.where((c) => !c.isDefault).toList();

    return jsonEncode({
      'version': '1.1',
      'exportDate': DateTime.now().toIso8601String(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'customCategories': customCategories.map((c) => c.toJson()).toList(),
    });
  }

  // Import from JSON
  Future<bool> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Import custom categories first
      if (data.containsKey('customCategories')) {
        final categoriesList = data['customCategories'] as List;
        final customCategories = categoriesList
            .map((json) => FinanceCategory.fromJson(json))
            .toList();
        await saveCategories(customCategories);
      }

      final transactionsList = data['transactions'] as List;
      final transactions = transactionsList
          .map((json) => FinanceTransaction.fromJson(json))
          .toList();

      await saveTransactions(transactions);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Budget management
  Future<void> saveBudget(Map<FinanceCategory, double> budget) async {
    final prefs = await SharedPreferences.getInstance();
    final budgetMap = budget.map((key, value) => MapEntry(key.id, value));
    await prefs.setString(_budgetKey, jsonEncode(budgetMap));
  }

  Future<Map<FinanceCategory, double>> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_budgetKey);

    if (jsonString == null) return {};

    final categories = await loadCategories();
    final budgetMap = jsonDecode(jsonString) as Map<String, dynamic>;

    final Map<FinanceCategory, double> result = {};
    budgetMap.forEach((key, value) {
      final category = categories.firstWhere(
        (c) => c.id == key,
        orElse: () =>
            FinanceCategory.defaultCategories.last, // Fallback to Other Expense
      );
      result[category] = (value as num).toDouble();
    });

    return result;
  }
}
