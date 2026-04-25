import 'package:expense_ai_app/core/themes/app_theme.dart';
import 'package:expense_ai_app/core/providers/connectivity_provider.dart';
import 'package:expense_ai_app/features/ai_advisor/data/services/ai_cache_service.dart';
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:expense_ai_app/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_ai_app/features/expense/presentation/widgets/add_expense_sheet.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerStatefulWidget {
  final VoidCallback onOpenProfile;

  const HomePage({super.key, required this.onOpenProfile});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final AiCacheService _cacheService = AiCacheService();
  String? _aiInsight;
  bool _loadingInsight = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInsight);
  }

  Future<void> _loadInsight() async {
    final cached = await _cacheService.getTodayAnalysis();
    if (!mounted) return;
    if (cached != null) {
      setState(() => _aiInsight = cached);
      return;
    }
    await _refreshInsight();
  }

  Future<void> _refreshInsight() async {
    final summary = ref.read(monthlyFinanceSnapshotProvider);
    final topCategories = ref.read(topSpendingCategoriesProvider);
    if (summary.income == 0 && summary.expenses == 0 && topCategories.isEmpty) return;

    setState(() => _loadingInsight = true);

    final buffer = StringBuffer()
      ..writeln("Income: ${summary.income.toStringAsFixed(2)} FCFA")
      ..writeln("Expenses: ${summary.expenses.toStringAsFixed(2)} FCFA")
      ..writeln("Budget total: ${summary.budgetTotal.toStringAsFixed(2)} FCFA")
      ..writeln("Upcoming bills: ${summary.upcomingBills.toStringAsFixed(2)} FCFA")
      ..writeln("Safe to spend: ${summary.safeToSpend.toStringAsFixed(2)} FCFA");

    for (final item in topCategories) {
      buffer.writeln("${item.category.name}: ${item.amount.toStringAsFixed(2)} FCFA");
    }

    final advice = await ref.read(expenseRepositoryProvider).analyzeExpenses(buffer.toString());
    if (!mounted) return;

    if (advice != null && advice.trim().isNotEmpty) {
      await _cacheService.saveAnalysis(advice);
      setState(() => _aiInsight = advice);
    } else {
      setState(
        () => _aiInsight =
            "Summary: Your month is still taking shape.\nWatch: Keep logging every expense.\nNext: Set one budget to unlock guidance.",
      );
    }

    setState(() => _loadingInsight = false);
  }

  Future<void> _openComposer({bool isIncome = false}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseSheet(initialIsIncome: isIncome),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ref.watch(monthlyFinanceSnapshotProvider);
    final categories = ref.watch(topSpendingCategoriesProvider);
    final recurring = ref.watch(upcomingRecurringProvider);
    final pendingSync = ref.watch(pendingSyncCountProvider);
    final connection = ref.watch(connectivityProvider);
    final expensesAsync = ref.watch(expenseListProvider);
    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());
    final hasData = expensesAsync.asData?.value.isNotEmpty ?? false;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Your money, calmer", style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text(
                          toBeginningOfSentenceCase(monthLabel) ?? monthLabel,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _SyncPill(isOffline: connection == ConnectionStatus.offline, pendingSync: pendingSync),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: widget.onOpenProfile,
                    borderRadius: BorderRadius.circular(18),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _HeroCard(summary: summary, currency: currency),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      label: 'Add expense',
                      subtitle: 'Log a spend fast',
                      icon: Icons.remove_circle_outline_rounded,
                      onTap: () => _openComposer(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      label: 'Add income',
                      subtitle: 'Track money in',
                      icon: Icons.add_circle_outline_rounded,
                      onTap: () => _openComposer(isIncome: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      label: 'Smart add',
                      subtitle: 'Coming soon',
                      icon: Icons.auto_awesome_outlined,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Smart capture is reserved for the next wave.')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InsightCard(insight: _aiInsight, isLoading: _loadingInsight, onRefresh: _refreshInsight),
              const SizedBox(height: 16),
              if (!hasData)
                _EmptyStateCard(onTap: _openComposer)
              else ...[
                _SectionCard(
                  title: 'Top categories',
                  subtitle: 'Where this month is going',
                  child: categories.isEmpty
                      ? Text('Add a few expenses to see category patterns.', style: theme.textTheme.bodyMedium)
                      : Column(
                          children: categories
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _CategoryRow(item: item, total: summary.expenses),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Upcoming bills',
                  subtitle: 'Recurring payments still ahead',
                  trailing: Text(currency.format(summary.upcomingBills), style: theme.textTheme.titleMedium),
                  child: recurring.isEmpty
                      ? Text(
                          'No upcoming recurring payments for the rest of this month.',
                          style: theme.textTheme.bodyMedium,
                        )
                      : Column(
                          children: recurring
                              .take(3)
                              .map((item) => _RecurringRow(item: item, currency: currency))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Spending rhythm',
                  subtitle: 'Last 6 months',
                  child: SizedBox(
                    height: 180,
                    child: _MiniTrendChart(expenses: ref.watch(allExpensesProvider).value ?? const <Expense>[]),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _SyncPill extends StatelessWidget {
  final bool isOffline;
  final int pendingSync;

  const _SyncPill({required this.isOffline, required this.pendingSync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isOffline
        ? 'Offline'
        : pendingSync > 0
        ? '$pendingSync pending'
        : 'Synced';
    final color = isOffline
        ? theme.colorScheme.secondaryContainer
        : pendingSync > 0
        ? theme.colorScheme.primaryContainer
        : const Color(0xFFDCE8DF);
    final foreground = isOffline
        ? theme.colorScheme.onSecondaryContainer
        : pendingSync > 0
        ? theme.colorScheme.onPrimaryContainer
        : AppTheme.moss;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: foreground, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final MonthlyFinanceSnapshot summary;
  final NumberFormat currency;

  const _HeroCard({required this.summary, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeColor = switch (summary.budgetStatus) {
      BudgetStatus.underControl => AppTheme.moss,
      BudgetStatus.caution => AppTheme.amber,
      BudgetStatus.overLimit => AppTheme.coral,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [theme.colorScheme.surface, theme.colorScheme.primaryContainer.withValues(alpha: 0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Remaining this month', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            currency.format(summary.safeToSpend),
            style: theme.textTheme.headlineLarge?.copyWith(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.daysLeft} day${summary.daysLeft == 1 ? '' : 's'} left to pace your spending',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: summary.budgetProgress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              minHeight: 10,
              color: safeColor,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricStat(label: 'Income', value: currency.format(summary.income)),
              ),
              Expanded(
                child: _MetricStat(label: 'Spent', value: currency.format(summary.expenses)),
              ),
              Expanded(
                child: _MetricStat(
                  label: 'Budgets used',
                  value: summary.budgetTotal > 0
                      ? '${(summary.budgetProgress * 100).round()}%'
                      : currency.format(summary.netBalance),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricStat extends StatelessWidget {
  final String label;
  final String value;

  const _MetricStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({required this.label, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 18),
            Text(label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String? insight;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _InsightCard({required this.insight, required this.isLoading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.secondary),
              const SizedBox(width: 10),
              Expanded(child: Text('Monthly insight', style: theme.textTheme.titleMedium)),
              TextButton(onPressed: isLoading ? null : onRefresh, child: const Text('Refresh')),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
            )
          else
            Text(
              insight ??
                  'Summary: Your month is still taking shape.\nWatch: Keep logging every expense.\nNext: Set a budget to unlock better guidance.',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.subtitle, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySpend item;
  final double total;

  const _CategoryRow({required this.item, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total <= 0 ? 0.0 : item.amount / total;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Color(item.category.color ?? 0xFFE7DFD1),
          child: Icon(
            IconData(item.category.icon ?? Icons.category.codePoint, fontFamily: 'MaterialIcons'),
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(item.category.name, style: theme.textTheme.titleMedium)),
                  Text('${(ratio * 100).round()}%', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: Color(item.category.color ?? AppTheme.moss.toARGB32()),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecurringRow extends StatelessWidget {
  final ExpenseWithCategory item;
  final NumberFormat currency;

  const _RecurringRow({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate = item.expense.nextRecurrenceDate;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              IconData(item.category?.icon ?? Icons.event_repeat.codePoint, fontFamily: 'MaterialIcons'),
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.expense.description ?? item.category?.name ?? 'Recurring bill',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  dueDate == null ? 'No due date' : DateFormat('dd MMM').format(dueDate),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(currency.format(item.expense.amount), style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _MiniTrendChart extends StatelessWidget {
  final List<Expense> expenses;

  const _MiniTrendChart({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthlyTotals = <String, double>{};

    for (int index = 5; index >= 0; index--) {
      final monthDate = DateTime(now.year, now.month - index, 1);
      monthlyTotals['${monthDate.year}-${monthDate.month}'] = 0;
    }

    for (final expense in expenses) {
      if (expense.isIncome) continue;
      final key = '${expense.date.year}-${expense.date.month}';
      if (monthlyTotals.containsKey(key)) {
        monthlyTotals[key] = monthlyTotals[key]! + expense.amount;
      }
    }

    final keys = monthlyTotals.keys.toList();
    final maxValue = monthlyTotals.values.fold<double>(0, (max, value) => value > max ? value : max);
    if (maxValue == 0) {
      return Center(child: Text('More history will unlock your trend view.', style: theme.textTheme.bodyMedium));
    }

    return BarChart(
      BarChartData(
        maxY: maxValue * 1.2,
        alignment: BarChartAlignment.spaceBetween,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final label = keys[value.toInt()];
                final month = int.parse(label.split('-')[1]);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][month - 1],
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: monthlyTotals.entries.toList().asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                width: 18,
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final Future<void> Function({bool isIncome}) onTap;

  const _EmptyStateCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Start your month with clarity', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            'Add your first expense or income to unlock safe-to-spend, recurring bill forecasting, and monthly AI insights.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: () => onTap(isIncome: false), child: const Text('Add first transaction')),
        ],
      ),
    );
  }
}
