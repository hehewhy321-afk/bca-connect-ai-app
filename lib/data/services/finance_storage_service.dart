import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance_transaction.dart';

class FinanceStorageService {
  static const String _transactionsKey = 'finance_transactions';
  static const String _budgetKey = 'finance_budget';

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
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => FinanceTransaction.fromJson(json)).toList();
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

  // Export to JSON
  Future<String> exportToJson() async {
    final transactions = await loadTransactions();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    return jsonEncode({
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'transactions': jsonList,
    });
  }

  // Import from JSON
  Future<bool> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
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
  Future<void> saveBudget(Map<TransactionCategory, double> budget) async {
    final prefs = await SharedPreferences.getInstance();
    final budgetMap = budget.map((key, value) => MapEntry(key.name, value));
    await prefs.setString(_budgetKey, jsonEncode(budgetMap));
  }

  Future<Map<TransactionCategory, double>> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_budgetKey);
    
    if (jsonString == null) return {};
    
    final budgetMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return budgetMap.map((key, value) => MapEntry(
      TransactionCategory.values.firstWhere((e) => e.name == key),
      (value as num).toDouble(),
    ));
  }
}
