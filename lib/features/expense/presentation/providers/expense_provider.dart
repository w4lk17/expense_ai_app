import 'package:expense_ai_app/features/ai_advisor/data/services/ai_service_factory.dart';
import 'package:expense_ai_app/features/ai_advisor/presentation/providers/ai_provider_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_ai_app/core/providers/database_provider.dart';
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:expense_ai_app/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:expense_ai_app/features/expense/domain/repositories/expense_repository.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum BudgetStatus { underControl, caution, overLimit }

enum ActivityDateFilter { all, thisMonth, last30Days, thisYear }

enum TransactionTypeFilter { all, expense, income }

enum SyncStatusFilter { all, synced, pending }

class ActivityFilterState {
  final String query;
  final ActivityDateFilter dateFilter;
  final int? categoryId;
  final TransactionTypeFilter typeFilter;
  final SyncStatusFilter syncFilter;

  const ActivityFilterState({
    this.query = '',
    this.dateFilter = ActivityDateFilter.all,
    this.categoryId,
    this.typeFilter = TransactionTypeFilter.all,
    this.syncFilter = SyncStatusFilter.all,
  });

  ActivityFilterState copyWith({
    String? query,
    ActivityDateFilter? dateFilter,
    int? categoryId,
    bool resetCategory = false,
    TransactionTypeFilter? typeFilter,
    SyncStatusFilter? syncFilter,
  }) {
    return ActivityFilterState(
      query: query ?? this.query,
      dateFilter: dateFilter ?? this.dateFilter,
      categoryId: resetCategory ? null : categoryId ?? this.categoryId,
      typeFilter: typeFilter ?? this.typeFilter,
      syncFilter: syncFilter ?? this.syncFilter,
    );
  }
}

class CategorySpend {
  final Category category;
  final double amount;

  const CategorySpend({required this.category, required this.amount});
}

class CategoryBudgetHealth {
  final Category category;
  final double spent;
  final double limit;
  final BudgetStatus status;

  const CategoryBudgetHealth({
    required this.category,
    required this.spent,
    required this.limit,
    required this.status,
  });

  double get ratio => limit <= 0 ? 0 : spent / limit;
}

class MonthlyFinanceSnapshot {
  final double income;
  final double expenses;
  final double budgetTotal;
  final double upcomingBills;
  final double safeToSpend;
  final double netBalance;
  final int daysLeft;
  final BudgetStatus budgetStatus;

  const MonthlyFinanceSnapshot({
    required this.income,
    required this.expenses,
    required this.budgetTotal,
    required this.upcomingBills,
    required this.safeToSpend,
    required this.netBalance,
    required this.daysLeft,
    required this.budgetStatus,
  });

  double get usageBase =>
      budgetTotal > 0 ? budgetTotal : (income > 0 ? income : expenses);

  double get budgetProgress =>
      usageBase <= 0 ? 0 : (expenses / usageBase).clamp(0.0, 1.0);
}

// Provider pour le Repository
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = Supabase.instance.client;
  final aiProvider = ref.watch(aiProviderSettingsProvider);
  final aiService = OpenAIService(provider: aiProvider);
  return ExpenseRepositoryImpl(db, supabase, aiService);
});

final categoryListProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getAllCategories();
});

final expenseListProvider = StreamProvider<List<ExpenseWithCategory>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.watchAllExpensesWithCategory();
});

final activityFiltersProvider = StateProvider<ActivityFilterState>((ref) {
  return const ActivityFilterState();
});

final filteredExpenseListProvider = Provider<List<ExpenseWithCategory>>((ref) {
  final filters = ref.watch(activityFiltersProvider);
  final expensesAsync = ref.watch(expenseListProvider);

  return expensesAsync.maybeWhen(
    data: (items) {
      final now = DateTime.now();
      return items.where((item) {
        final expense = item.expense;
        final query = filters.query.trim().toLowerCase();

        if (query.isNotEmpty) {
          final haystack = [
            expense.description ?? '',
            item.category?.name ?? '',
          ].join(' ').toLowerCase();
          if (!haystack.contains(query)) return false;
        }

        if (filters.categoryId != null &&
            expense.categoryId != filters.categoryId) {
          return false;
        }

        switch (filters.typeFilter) {
          case TransactionTypeFilter.expense:
            if (expense.isIncome) return false;
            break;
          case TransactionTypeFilter.income:
            if (!expense.isIncome) return false;
            break;
          case TransactionTypeFilter.all:
            break;
        }

        switch (filters.syncFilter) {
          case SyncStatusFilter.synced:
            if (!expense.isSynced) return false;
            break;
          case SyncStatusFilter.pending:
            if (expense.isSynced) return false;
            break;
          case SyncStatusFilter.all:
            break;
        }

        switch (filters.dateFilter) {
          case ActivityDateFilter.thisMonth:
            if (expense.date.month != now.month ||
                expense.date.year != now.year) {
              return false;
            }
            break;
          case ActivityDateFilter.last30Days:
            if (expense.date.isBefore(now.subtract(const Duration(days: 30)))) {
              return false;
            }
            break;
          case ActivityDateFilter.thisYear:
            if (expense.date.year != now.year) return false;
            break;
          case ActivityDateFilter.all:
            break;
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

final expensesByCategoryProvider = Provider<Map<Category, double>>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  final now = DateTime.now();

  return expensesAsync.maybeWhen(
    data: (items) {
      final map = <Category, double>{};
      for (final item in items) {
        if (item.category == null ||
            item.expense.isIncome ||
            item.expense.date.month != now.month ||
            item.expense.date.year != now.year) {
          continue;
        }

        map.update(
          item.category!,
          (value) => value + item.expense.amount,
          ifAbsent: () => item.expense.amount,
        );
      }
      return map;
    },
    orElse: () => {},
  );
});

final topSpendingCategoriesProvider = Provider<List<CategorySpend>>((ref) {
  final categories = ref.watch(expensesByCategoryProvider).entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return categories
      .take(4)
      .map((entry) => CategorySpend(category: entry.key, amount: entry.value))
      .toList();
});

final totalMonthProvider = Provider<double>((ref) {
  final summary = ref.watch(monthlyFinanceSnapshotProvider);
  return summary.expenses;
});

final budgetsProvider = FutureProvider<Map<int, double>>((ref) async {
  return ref.watch(expenseRepositoryProvider).getBudgetsForCurrentMonth();
});

final allExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  return ref.watch(expenseRepositoryProvider).getAllExpenses();
});

final totalExpensesMonthProvider = Provider<double>((ref) {
  return ref.watch(monthlyFinanceSnapshotProvider).expenses;
});

final totalIncomeMonthProvider = Provider<double>((ref) {
  return ref.watch(monthlyFinanceSnapshotProvider).income;
});

final netBalanceProvider = Provider<double>((ref) {
  return ref.watch(monthlyFinanceSnapshotProvider).netBalance;
});

final pendingSyncCountProvider = Provider<int>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  return expensesAsync.maybeWhen(
    data: (items) => items.where((item) => !item.expense.isSynced).length,
    orElse: () => 0,
  );
});

final upcomingRecurringProvider = Provider<List<ExpenseWithCategory>>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  final today = DateTime.now();
  final startToday = DateTime(today.year, today.month, today.day);
  final endWindow = DateTime(today.year, today.month + 1, 0, 23, 59, 59);

  return expensesAsync.maybeWhen(
    data: (items) {
      final upcoming = items.where((item) {
        final dueDate = item.expense.nextRecurrenceDate;
        return item.expense.isRecurring &&
            !item.expense.isIncome &&
            dueDate != null &&
            !dueDate.isBefore(startToday) &&
            !dueDate.isAfter(endWindow);
      }).toList();

      upcoming.sort((a, b) {
        final left = a.expense.nextRecurrenceDate ?? DateTime(9999);
        final right = b.expense.nextRecurrenceDate ?? DateTime(9999);
        return left.compareTo(right);
      });
      return upcoming;
    },
    orElse: () => [],
  );
});

final recentDescriptionsProvider = Provider<List<String>>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  return expensesAsync.maybeWhen(
    data: (items) {
      final unique = <String>[];
      for (final item in items) {
        final description = item.expense.description?.trim();
        if (description == null ||
            description.isEmpty ||
            unique.contains(description)) {
          continue;
        }
        unique.add(description);
        if (unique.length == 5) break;
      }
      return unique;
    },
    orElse: () => [],
  );
});

final monthlyFinanceSnapshotProvider = Provider<MonthlyFinanceSnapshot>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  final budgetsAsync = ref.watch(budgetsProvider);
  final upcomingBills = ref.watch(upcomingRecurringProvider);
  final now = DateTime.now();

  return expensesAsync.maybeWhen(
    data: (items) {
      double income = 0;
      double expenses = 0;

      for (final item in items) {
        if (item.expense.date.month != now.month ||
            item.expense.date.year != now.year) {
          continue;
        }

        if (item.expense.isIncome) {
          income += item.expense.amount;
        } else {
          expenses += item.expense.amount;
        }
      }

      final budgetTotal =
          budgetsAsync.asData?.value.values.fold<double>(
            0,
            (sum, item) => sum + item,
          ) ??
          0;
      final recurringTotal = upcomingBills.fold<double>(
        0,
        (sum, item) => sum + item.expense.amount,
      );
      final planningBase = budgetTotal > 0 ? budgetTotal : income;
      final safeToSpend = planningBase - expenses - recurringTotal;
      final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
      final ratio = planningBase <= 0 ? 0 : expenses / planningBase;

      return MonthlyFinanceSnapshot(
        income: income,
        expenses: expenses,
        budgetTotal: budgetTotal,
        upcomingBills: recurringTotal,
        safeToSpend: safeToSpend,
        netBalance: income - expenses,
        daysLeft: daysLeft,
        budgetStatus: budgetStatusFor(ratio.toDouble()),
      );
    },
    orElse: () => const MonthlyFinanceSnapshot(
      income: 0,
      expenses: 0,
      budgetTotal: 0,
      upcomingBills: 0,
      safeToSpend: 0,
      netBalance: 0,
      daysLeft: 0,
      budgetStatus: BudgetStatus.underControl,
    ),
  );
});

final categoryBudgetHealthProvider = Provider<List<CategoryBudgetHealth>>((
  ref,
) {
  final categoriesAsync = ref.watch(categoryListProvider);
  final budgetsAsync = ref.watch(budgetsProvider);
  final currentSpending = ref.watch(expensesByCategoryProvider);

  return categoriesAsync.maybeWhen(
    data: (categories) {
      final budgets = budgetsAsync.asData?.value ?? <int, double>{};
      final health = <CategoryBudgetHealth>[];

      for (final category in categories) {
        final limit = budgets[category.id] ?? 0;
        if (limit <= 0) continue;

        final spent = currentSpending[category] ?? 0;
        health.add(
          CategoryBudgetHealth(
            category: category,
            spent: spent,
            limit: limit,
            status: budgetStatusFor(limit <= 0 ? 0 : spent / limit),
          ),
        );
      }

      health.sort((a, b) => b.ratio.compareTo(a.ratio));
      return health;
    },
    orElse: () => [],
  );
});

BudgetStatus budgetStatusFor(double ratio) {
  if (ratio >= 1) return BudgetStatus.overLimit;
  if (ratio >= 0.7) return BudgetStatus.caution;
  return BudgetStatus.underControl;
}
