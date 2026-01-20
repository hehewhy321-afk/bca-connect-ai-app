import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/models/finance_transaction.dart';
import '../../../data/services/finance_storage_service.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/constants/easter_eggs.dart';
import '../../widgets/easter_egg_widget.dart';

// Providers
final financeStorageProvider = Provider((ref) => FinanceStorageService());

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<List<FinanceTransaction>>>((ref) {
  return TransactionsNotifier(ref.read(financeStorageProvider));
});

class TransactionsNotifier extends StateNotifier<AsyncValue<List<FinanceTransaction>>> {
  final FinanceStorageService _storage;

  TransactionsNotifier(this._storage) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = const AsyncValue.loading();
    try {
      final transactions = await _storage.loadTransactions();
      state = AsyncValue.data(transactions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTransaction(FinanceTransaction transaction) async {
    await _storage.addTransaction(transaction);
    await loadTransactions();
  }

  Future<void> updateTransaction(FinanceTransaction transaction) async {
    await _storage.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _storage.deleteTransaction(id);
    await loadTransactions();
  }

  Future<void> clearAll() async {
    await _storage.clearAllTransactions();
    await loadTransactions();
  }

  Future<String> exportData() async {
    return await _storage.exportToJson();
  }

  Future<bool> importData(String jsonString) async {
    final success = await _storage.importFromJson(jsonString);
    if (success) {
      await loadTransactions();
    }
    return success;
  }
}

final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());
final selectedFilterProvider = StateProvider<String>((ref) => 'all'); // all, income, expense

class FinanceTrackerScreen extends ConsumerWidget {
  const FinanceTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: EasterEggWidget(
          soundFile: EasterEggs.finance.soundFile,
          emoji: EasterEggs.finance.emoji,
          message: EasterEggs.finance.message,
          child: const Text('Finance Tracker'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.setting_2),
            onPressed: () => _showOptionsMenu(context, ref),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          // Filter by month
          final monthTransactions = transactions.where((t) {
            return t.date.year == selectedMonth.year &&
                   t.date.month == selectedMonth.month;
          }).toList();

          // Apply filter
          final filteredTransactions = selectedFilter == 'all'
              ? monthTransactions
              : monthTransactions.where((t) => 
                  t.type.name == selectedFilter).toList();

          // Calculate totals
          final income = monthTransactions
              .where((t) => t.type == TransactionType.income)
              .fold(0.0, (sum, t) => sum + t.amount);
          final expense = monthTransactions
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (sum, t) => sum + t.amount);
          final balance = income - expense;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Selector
                _MonthSelector(
                  selectedMonth: selectedMonth,
                  onMonthChanged: (month) {
                    ref.read(selectedMonthProvider.notifier).state = month;
                  },
                ),
                const SizedBox(height: 20),

                // Summary Cards
                _SummaryCards(
                  income: income,
                  expense: expense,
                  balance: balance,
                ),
                const SizedBox(height: 20),

                // Charts
                if (monthTransactions.isNotEmpty) ...[
                  _ChartsSection(transactions: monthTransactions),
                  const SizedBox(height: 20),
                ],

                // Filter Chips
                _FilterChips(
                  selectedFilter: selectedFilter,
                  onFilterChanged: (filter) {
                    ref.read(selectedFilterProvider.notifier).state = filter;
                  },
                ),
                const SizedBox(height: 16),

                // Transactions List
                if (filteredTransactions.isEmpty)
                  _EmptyState()
                else
                  _TransactionsList(
                    transactions: filteredTransactions,
                    onEdit: (transaction) => _showAddEditDialog(context, ref, transaction: transaction),
                    onDelete: (id) => ref.read(transactionsProvider.notifier).deleteTransaction(id),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, ref),
        icon: const Icon(Iconsax.add),
        label: const Text('Add Transaction'),
        backgroundColor: ModernTheme.primaryOrange,
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.export_1),
              title: const Text('Export Data'),
              onTap: () async {
                Navigator.pop(context);
                await _exportData(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.import),
              title: const Text('Import Data'),
              onTap: () async {
                Navigator.pop(context);
                await _importData(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.trash, color: Colors.red),
              title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _clearAllData(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    // Show modern dialog with options
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Iconsax.document_upload, color: ModernTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Export Finance Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how to export your finance data:'),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ModernTheme.primaryOrange.withValues(alpha: 0.1),
                    ModernTheme.primaryOrange.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ListTile(
                leading: const Icon(Iconsax.save_2, color: ModernTheme.primaryOrange, size: 28),
                title: const Text('Save to Device', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Save in Downloads folder'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(context, 'save'),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.1),
                    Colors.blue.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ListTile(
                leading: const Icon(Iconsax.share, color: Colors.blue, size: 28),
                title: const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Share via other apps'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(context, 'share'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (action == null) return;

    try {
      final jsonData = await ref.read(transactionsProvider.notifier).exportData();
      final fileName = 'finance-export-${DateFormat('yyyy-MM-dd-HHmmss').format(DateTime.now())}.json';
      
      if (action == 'save') {
        // Save to Downloads folder
        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final file = File('${appDir.path}/$fileName');
          await file.writeAsString(jsonData);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to: ${file.path}'),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () {},
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } else {
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(jsonData);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Finance data saved to Downloads folder!'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      } else {
        // Share via other apps
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonData);
        
        if (context.mounted) {
          // ignore: deprecated_member_use
          await Share.shareXFiles(
            [XFile(file.path)],
            subject: 'Finance Tracker Export',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final success = await ref.read(transactionsProvider.notifier).importData(jsonString);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Import successful!' : 'Import failed'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will delete all transactions. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(transactionsProvider.notifier).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    }
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref, {FinanceTransaction? transaction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditTransactionSheet(
        transaction: transaction,
        onSave: (newTransaction) async {
          if (transaction == null) {
            await ref.read(transactionsProvider.notifier).addTransaction(newTransaction);
          } else {
            await ref.read(transactionsProvider.notifier).updateTransaction(newTransaction);
          }
        },
      ),
    );
  }
}


// Month Selector Widget
class _MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;

  const _MonthSelector({
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Iconsax.arrow_left_2),
            onPressed: () {
              final newMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
              onMonthChanged(newMonth);
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.arrow_right_3),
            onPressed: () {
              final newMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
              onMonthChanged(newMonth);
            },
          ),
        ],
      ),
    );
  }
}

// Summary Cards Widget
class _SummaryCards extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const _SummaryCards({
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Balance Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                'Total Balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rs ${balance.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Income & Expense Cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Income',
                amount: income,
                icon: Iconsax.arrow_down_1,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Expense',
                amount: expense,
                icon: Iconsax.arrow_up_3,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rs ${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Charts Section with Income/Expense Toggle
class _ChartsSection extends StatefulWidget {
  final List<FinanceTransaction> transactions;

  const _ChartsSection({required this.transactions});

  @override
  State<_ChartsSection> createState() => _ChartsSectionState();
}

class _ChartsSectionState extends State<_ChartsSection> {
  bool _showExpense = true; // true = expense, false = income

  @override
  Widget build(BuildContext context) {
    // Calculate category totals for expenses
    final Map<TransactionCategory, double> expenseTotals = {};
    final Map<TransactionCategory, double> incomeTotals = {};
    
    for (var transaction in widget.transactions) {
      if (transaction.type == TransactionType.expense) {
        expenseTotals[transaction.category] = 
            (expenseTotals[transaction.category] ?? 0) + transaction.amount;
      } else {
        incomeTotals[transaction.category] = 
            (incomeTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    final categoryTotals = _showExpense ? expenseTotals : incomeTotals;
    
    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Toggle Buttons
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToggleButton(
                      label: 'Expense',
                      isSelected: _showExpense,
                      color: Colors.red,
                      onTap: () {
                        if (!_showExpense) {
                          setState(() => _showExpense = true);
                        }
                      },
                    ),
                    _ToggleButton(
                      label: 'Income',
                      isSelected: !_showExpense,
                      color: Colors.green,
                      onTap: () {
                        if (_showExpense) {
                          setState(() => _showExpense = false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Pie Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: categoryTotals.entries.map((entry) {
                  final total = categoryTotals.values.reduce((a, b) => a + b);
                  final percentage = (entry.value / total * 100);
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    color: entry.key.color,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: categoryTotals.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: entry.key.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key.displayName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Toggle Button Widget
class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// Filter Chips
class _FilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const _FilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'All',
          value: 'all',
          isSelected: selectedFilter == 'all',
          onTap: () => onFilterChanged('all'),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Income',
          value: 'income',
          isSelected: selectedFilter == 'income',
          onTap: () => onFilterChanged('income'),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Expense',
          value: 'expense',
          isSelected: selectedFilter == 'expense',
          onTap: () => onFilterChanged('expense'),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ModernTheme.primaryOrange : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? ModernTheme.primaryOrange : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// Empty State
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            Iconsax.empty_wallet,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction to get started',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Transactions List
class _TransactionsList extends StatelessWidget {
  final List<FinanceTransaction> transactions;
  final Function(FinanceTransaction) onEdit;
  final Function(String) onDelete;

  const _TransactionsList({
    required this.transactions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Group by date
    final Map<String, List<FinanceTransaction>> groupedTransactions = {};
    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }

    // Sort by date descending
    final sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedKeys.map((dateKey) {
        final dayTransactions = groupedTransactions[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                DateFormat('EEEE, MMM dd').format(date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...dayTransactions.map((transaction) => _TransactionCard(
              transaction: transaction,
              onEdit: () => onEdit(transaction),
              onDelete: () => onDelete(transaction.id),
            )),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final FinanceTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: transaction.category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            transaction.category.icon,
            color: transaction.category.color,
            size: 24,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          transaction.category.displayName,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'} Rs ${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: const Row(
                    children: [
                      Icon(Iconsax.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Row(
                    children: [
                      Icon(Iconsax.trash, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}


// Add/Edit Transaction Sheet
class _AddEditTransactionSheet extends StatefulWidget {
  final FinanceTransaction? transaction;
  final Function(FinanceTransaction) onSave;

  const _AddEditTransactionSheet({
    this.transaction,
    required this.onSave,
  });

  @override
  State<_AddEditTransactionSheet> createState() => _AddEditTransactionSheetState();
}

class _AddEditTransactionSheetState extends State<_AddEditTransactionSheet> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TransactionType _selectedType;
  late TransactionCategory _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? '',
    );
    _selectedType = widget.transaction?.type ?? TransactionType.expense;
    _selectedCategory = widget.transaction?.category ?? TransactionCategory.food;
    _selectedDate = widget.transaction?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = TransactionCategoryExtension.getByType(_selectedType);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.transaction == null ? 'Add Transaction' : 'Edit Transaction',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Type Selector
                Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        label: 'Income',
                        icon: Iconsax.arrow_down_1,
                        color: Colors.green,
                        isSelected: _selectedType == TransactionType.income,
                        onTap: () {
                          setState(() {
                            _selectedType = TransactionType.income;
                            _selectedCategory = TransactionCategory.salary;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeButton(
                        label: 'Expense',
                        icon: Iconsax.arrow_up_3,
                        color: Colors.red,
                        isSelected: _selectedType == TransactionType.expense,
                        onTap: () {
                          setState(() {
                            _selectedType = TransactionType.expense;
                            _selectedCategory = TransactionCategory.food;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Amount Field
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'Rs ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description Field
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Selector
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category.color.withValues(alpha: 0.2)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? category.color
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              size: 18,
                              color: isSelected ? category.color : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              category.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? category.color : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Iconsax.calendar),
                  title: const Text('Date'),
                  trailing: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saveTransaction,
                    style: FilledButton.styleFrom(
                      backgroundColor: ModernTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.transaction == null ? 'Add Transaction' : 'Update Transaction',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveTransaction() {
    final amount = double.tryParse(_amountController.text);
    final description = _descriptionController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    final transaction = FinanceTransaction(
      id: widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      description: description,
      date: _selectedDate,
      createdAt: widget.transaction?.createdAt ?? DateTime.now(),
    );

    widget.onSave(transaction);
    Navigator.pop(context);
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
