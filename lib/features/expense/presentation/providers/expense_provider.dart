import 'package:expense_ai_app/features/ai_advisor/data/services/ai_service_factory.dart';
import 'package:expense_ai_app/features/ai_advisor/presentation/providers/ai_provider_settings.dart';
import 'package:expense_ai_app/core/providers/database_provider.dart';
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:expense_ai_app/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:expense_ai_app/features/expense/data/services/budget_alert_notification_service.dart';
import 'package:expense_ai_app/features/expense/domain/repositories/expense_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum BudgetStatus { underControl, caution, overLimit }

enum BudgetAlertLevel { warning70, warning90, over100 }

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

class BudgetAlertState {
  final int categoryId;
  final String categoryName;
  final double spent;
  final double limit;
  final double ratio;
  final BudgetAlertLevel level;
  final String message;
  final String suggestion;
  final DateTime triggeredAt;
  final bool isDismissed;

  const BudgetAlertState({
    required this.categoryId,
    required this.categoryName,
    required this.spent,
    required this.limit,
    required this.ratio,
    required this.level,
    required this.message,
    required this.suggestion,
    required this.triggeredAt,
    required this.isDismissed,
  });

  String get title {
    switch (level) {
      case BudgetAlertLevel.warning70:
        return '$categoryName is nearing its budget';
      case BudgetAlertLevel.warning90:
        return '$categoryName is almost over budget';
      case BudgetAlertLevel.over100:
        return '$categoryName is over budget';
    }
  }
}

class BudgetAlertsSummary {
  final List<BudgetAlertState> activeAlerts;
  final bool notificationsEnabled;

  const BudgetAlertsSummary({
    this.activeAlerts = const [],
    this.notificationsEnabled = true,
  });

  BudgetAlertState? get highestPriorityAlert =>
      activeAlerts.isEmpty ? null : activeAlerts.first;

  int get visibleCount => activeAlerts.length;

  bool get hasAlerts => activeAlerts.isNotEmpty;

  BudgetAlertsSummary copyWith({
    List<BudgetAlertState>? activeAlerts,
    bool? notificationsEnabled,
  }) {
    return BudgetAlertsSummary(
      activeAlerts: activeAlerts ?? this.activeAlerts,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class BudgetAlertsController extends StateNotifier<BudgetAlertsSummary> {
  BudgetAlertsController(this.ref, this._notificationService)
    : super(const BudgetAlertsSummary());

  final Ref ref;
  final BudgetAlertNotificationService _notificationService;

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  static const String _notificationsEnabledKey = 'budget_alerts_enabled';

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _notificationService.initialize();

    final enabled = _prefs?.getBool(_notificationsEnabledKey) ?? true;
    state = state.copyWith(notificationsEnabled: enabled);

    if (enabled) {
      await _notificationService.requestPermissions();
    }

    _isInitialized = true;
    await reconcile();
  }

  Future<void> reconcile() async {
    if (!_isInitialized) return;

    final now = DateTime.now();
    final items = ref.read(categoryBudgetHealthProvider);
    final alerts = <BudgetAlertState>[];

    for (final item in items) {
      final level = budgetAlertLevelFor(item.ratio);
      if (level == null) continue;

      final dismissed =
          _prefs?.getBool(
            _dismissKey(
              year: now.year,
              month: now.month,
              categoryId: item.category.id,
              level: level,
            ),
          ) ??
          false;

      final alert = BudgetAlertState(
        categoryId: item.category.id,
        categoryName: item.category.name,
        spent: item.spent,
        limit: item.limit,
        ratio: item.ratio,
        level: level,
        message: budgetAlertMessageFor(level, item.category.name),
        suggestion: budgetAlertSuggestionFor(level),
        triggeredAt: now,
        isDismissed: dismissed,
      );

      if (!dismissed) {
        alerts.add(alert);
        await _notifyIfNeeded(alert, now);
      }
    }

    alerts.sort((left, right) {
      final priority = budgetAlertPriority(
        right.level,
      ).compareTo(budgetAlertPriority(left.level));
      if (priority != 0) return priority;
      return right.ratio.compareTo(left.ratio);
    });

    state = state.copyWith(activeAlerts: alerts);
  }

  Future<void> dismissAlert(BudgetAlertState alert) async {
    if (!_isInitialized) return;

    final now = DateTime.now();
    await _prefs?.setBool(
      _dismissKey(
        year: now.year,
        month: now.month,
        categoryId: alert.categoryId,
        level: alert.level,
      ),
      true,
    );

    state = state.copyWith(
      activeAlerts: state.activeAlerts
          .where(
            (item) =>
                item.categoryId != alert.categoryId ||
                item.level != alert.level,
          )
          .toList(),
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _prefs?.setBool(_notificationsEnabledKey, enabled);
    state = state.copyWith(notificationsEnabled: enabled);

    if (enabled) {
      await _notificationService.requestPermissions();
    }
  }

  Future<void> _notifyIfNeeded(BudgetAlertState alert, DateTime now) async {
    if (!state.notificationsEnabled) return;

    final key = _notifiedKey(
      year: now.year,
      month: now.month,
      categoryId: alert.categoryId,
    );
    final previous = _prefs?.getString(key);
    final previousLevel = previous == null
        ? null
        : BudgetAlertLevel.values.firstWhere(
            (item) => item.name == previous,
            orElse: () => BudgetAlertLevel.warning70,
          );

    if (previousLevel != null &&
        budgetAlertPriority(previousLevel) >=
            budgetAlertPriority(alert.level)) {
      return;
    }

    await _notificationService.showBudgetAlert(
      notificationId: _notificationId(
        year: now.year,
        month: now.month,
        categoryId: alert.categoryId,
      ),
      title: alert.title,
      body:
          '${alert.message} ${alert.suggestion} (${alert.spent.toStringAsFixed(0)} / ${alert.limit.toStringAsFixed(0)} FCFA)',
    );

    await _prefs?.setString(key, alert.level.name);
  }

  String _dismissKey({
    required int year,
    required int month,
    required int categoryId,
    required BudgetAlertLevel level,
  }) {
    return 'budget_alert_dismissed_${year}_${month}_${categoryId}_${level.name}';
  }

  String _notifiedKey({
    required int year,
    required int month,
    required int categoryId,
  }) {
    return 'budget_alert_notified_${year}_${month}_$categoryId';
  }

  int _notificationId({
    required int year,
    required int month,
    required int categoryId,
  }) {
    return (year * 100000) + (month * 1000) + categoryId;
  }
}

final budgetAlertNotificationServiceProvider =
    Provider<BudgetAlertNotificationService>((ref) {
      return LocalBudgetAlertNotificationService();
    });

final budgetAlertsControllerProvider =
    StateNotifierProvider<BudgetAlertsController, BudgetAlertsSummary>((ref) {
      return BudgetAlertsController(
        ref,
        ref.watch(budgetAlertNotificationServiceProvider),
      );
    });

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

BudgetAlertLevel? budgetAlertLevelFor(double ratio) {
  if (ratio >= 1) return BudgetAlertLevel.over100;
  if (ratio >= 0.9) return BudgetAlertLevel.warning90;
  if (ratio >= 0.7) return BudgetAlertLevel.warning70;
  return null;
}

int budgetAlertPriority(BudgetAlertLevel level) {
  switch (level) {
    case BudgetAlertLevel.warning70:
      return 1;
    case BudgetAlertLevel.warning90:
      return 2;
    case BudgetAlertLevel.over100:
      return 3;
  }
}

String budgetAlertMessageFor(BudgetAlertLevel level, String categoryName) {
  switch (level) {
    case BudgetAlertLevel.warning70:
      return '$categoryName has crossed 70% of its monthly budget.';
    case BudgetAlertLevel.warning90:
      return '$categoryName has crossed 90% of its monthly budget.';
    case BudgetAlertLevel.over100:
      return '$categoryName is now over budget for this month.';
  }
}

String budgetAlertSuggestionFor(BudgetAlertLevel level) {
  switch (level) {
    case BudgetAlertLevel.warning70:
      return 'Slow spending here before the category becomes a problem.';
    case BudgetAlertLevel.warning90:
      return 'Trim this category now to avoid going over the limit.';
    case BudgetAlertLevel.over100:
      return 'Pause non-essential spending in this category first.';
  }
}
