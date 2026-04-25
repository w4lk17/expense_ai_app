import 'package:drift/drift.dart' as drift;
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:expense_ai_app/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_ai_app/features/expense/presentation/widgets/add_expense_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({super.key});

  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    if (offset > _lastOffset && offset > 80 && _showFab) {
      setState(() => _showFab = false);
    } else if (offset < _lastOffset && !_showFab) {
      setState(() => _showFab = true);
    }
    _lastOffset = offset;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _duplicateExpense(Expense expense) async {
    final duplicated = ExpensesCompanion.insert(
      amount: expense.amount,
      date: DateTime.now(),
      description: drift.Value(expense.description),
      categoryId: drift.Value(expense.categoryId),
      paymentMethod: drift.Value(expense.paymentMethod),
      isRecurring: drift.Value(expense.isRecurring),
      isIncome: drift.Value(expense.isIncome),
      recurrenceInterval: drift.Value(expense.recurrenceInterval),
      nextRecurrenceDate: drift.Value(expense.nextRecurrenceDate),
    );

    await ref.read(expenseRepositoryProvider).addExpense(duplicated);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaction duplicated.')));
  }

  Future<void> _openEditor({Expense? expense}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseSheet(expenseToEdit: expense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
    final filters = ref.watch(activityFiltersProvider);
    final filtered = ref.watch(filteredExpenseListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    final groups = _groupExpenses(filtered);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            expandedHeight: 170,
            title: const Text('Activity'),
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 84, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search merchant or category',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (value) {
                          ref.read(activityFiltersProvider.notifier).state =
                              filters.copyWith(query: value);
                        },
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: _dateLabel(filters.dateFilter),
                              onTap: () => _pickDateFilter(filters),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: _typeLabel(filters.typeFilter),
                              onTap: () => _pickTypeFilter(filters),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: _syncLabel(filters.syncFilter),
                              onTap: () => _pickSyncFilter(filters),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: categoriesAsync.maybeWhen(
                                data: (categories) {
                                  Category? selected;
                                  for (final category in categories) {
                                    if (category.id == filters.categoryId) {
                                      selected = category;
                                      break;
                                    }
                                  }
                                  return selected?.name ?? 'All categories';
                                },
                                orElse: () => 'All categories',
                              ),
                              onTap: () => _pickCategoryFilter(filters),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No transactions match these filters yet.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final section = groups.entries.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 10),
                          child: Text(
                            section.key,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        ...section.value.map((item) {
                          final expense = item.expense;
                          final category = item.category;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: ValueKey('activity-${expense.id}'),
                              background: _SwipeAction(
                                alignment: Alignment.centerLeft,
                                color: theme.colorScheme.primaryContainer,
                                icon: Icons.copy_rounded,
                                label: 'Duplicate',
                              ),
                              secondaryBackground: _SwipeAction(
                                alignment: Alignment.centerRight,
                                color: theme.colorScheme.errorContainer,
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  await _duplicateExpense(expense);
                                  return false;
                                }

                                return await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Delete transaction?',
                                        ),
                                        content: const Text(
                                          'This action removes the transaction from your history.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (_) async {
                                await ref
                                    .read(expenseRepositoryProvider)
                                    .deleteExpense(expense);
                              },
                              child: InkWell(
                                onTap: () => _openEditor(expense: expense),
                                borderRadius: BorderRadius.circular(26),
                                child: Ink(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: Color(
                                          category?.color ?? 0xFFE7DFD1,
                                        ),
                                        child: Icon(
                                          IconData(
                                            category?.icon ??
                                                Icons
                                                    .payments_rounded
                                                    .codePoint,
                                            fontFamily: 'MaterialIcons',
                                          ),
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              expense.description?.isNotEmpty ==
                                                      true
                                                  ? expense.description!
                                                  : (category?.name ??
                                                        'Transaction'),
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _MetaPill(
                                                  label:
                                                      category?.name ??
                                                      'Unsorted',
                                                ),
                                                _MetaPill(
                                                  label: DateFormat(
                                                    'dd MMM',
                                                  ).format(expense.date),
                                                ),
                                                if (!expense.isSynced)
                                                  const _MetaPill(
                                                    label: 'Pending sync',
                                                    warning: true,
                                                  ),
                                                if (expense.isRecurring)
                                                  const _MetaPill(
                                                    label: 'Recurring',
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        currency.format(expense.amount),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: expense.isIncome
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurface,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }, childCount: groups.length),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AnimatedSlide(
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 220),
        child: AnimatedOpacity(
          opacity: _showFab ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          child: FloatingActionButton.extended(
            onPressed: _openEditor,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateFilter(ActivityFilterState filters) async {
    final value = await showModalBottomSheet<ActivityDateFilter>(
      context: context,
      builder: (context) => _EnumPicker<ActivityDateFilter>(
        title: 'Date range',
        values: ActivityDateFilter.values,
        selected: filters.dateFilter,
        labelBuilder: _dateLabel,
      ),
    );
    if (value == null) return;
    ref.read(activityFiltersProvider.notifier).state = filters.copyWith(
      dateFilter: value,
    );
  }

  Future<void> _pickTypeFilter(ActivityFilterState filters) async {
    final value = await showModalBottomSheet<TransactionTypeFilter>(
      context: context,
      builder: (context) => _EnumPicker<TransactionTypeFilter>(
        title: 'Transaction type',
        values: TransactionTypeFilter.values,
        selected: filters.typeFilter,
        labelBuilder: _typeLabel,
      ),
    );
    if (value == null) return;
    ref.read(activityFiltersProvider.notifier).state = filters.copyWith(
      typeFilter: value,
    );
  }

  Future<void> _pickSyncFilter(ActivityFilterState filters) async {
    final value = await showModalBottomSheet<SyncStatusFilter>(
      context: context,
      builder: (context) => _EnumPicker<SyncStatusFilter>(
        title: 'Sync state',
        values: SyncStatusFilter.values,
        selected: filters.syncFilter,
        labelBuilder: _syncLabel,
      ),
    );
    if (value == null) return;
    ref.read(activityFiltersProvider.notifier).state = filters.copyWith(
      syncFilter: value,
    );
  }

  Future<void> _pickCategoryFilter(ActivityFilterState filters) async {
    final categories = await ref.read(categoryListProvider.future);
    if (!mounted) return;

    final selectedId = await showModalBottomSheet<int?>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('All categories'),
              trailing: filters.categoryId == null
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(context, -1),
            ),
            ...categories.map(
              (category) => ListTile(
                title: Text(category.name),
                trailing: filters.categoryId == category.id
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, category.id),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedId == null) return;

    ref.read(activityFiltersProvider.notifier).state = selectedId == -1
        ? filters.copyWith(resetCategory: true)
        : filters.copyWith(categoryId: selectedId);
  }

  Map<String, List<ExpenseWithCategory>> _groupExpenses(
    List<ExpenseWithCategory> expenses,
  ) {
    final groups = <String, List<ExpenseWithCategory>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));

    for (final item in expenses) {
      final date = DateTime(
        item.expense.date.year,
        item.expense.date.month,
        item.expense.date.day,
      );
      final key = date == today
          ? 'Today'
          : date == yesterday
          ? 'Yesterday'
          : date.isAfter(weekStart.subtract(const Duration(days: 1)))
          ? 'This week'
          : 'Earlier';
      groups.putIfAbsent(key, () => []).add(item);
    }

    return groups;
  }
}

String _dateLabel(ActivityDateFilter filter) {
  switch (filter) {
    case ActivityDateFilter.thisMonth:
      return 'This month';
    case ActivityDateFilter.last30Days:
      return 'Last 30 days';
    case ActivityDateFilter.thisYear:
      return 'This year';
    case ActivityDateFilter.all:
      return 'All dates';
  }
}

String _typeLabel(TransactionTypeFilter filter) {
  switch (filter) {
    case TransactionTypeFilter.expense:
      return 'Expenses';
    case TransactionTypeFilter.income:
      return 'Income';
    case TransactionTypeFilter.all:
      return 'All types';
  }
}

String _syncLabel(SyncStatusFilter filter) {
  switch (filter) {
    case SyncStatusFilter.synced:
      return 'Synced';
    case SyncStatusFilter.pending:
      return 'Pending';
    case SyncStatusFilter.all:
      return 'All sync states';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: const Icon(Icons.tune_rounded, size: 16),
      label: Text(label),
    );
  }
}

class _SwipeAction extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeAction({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
      ),
      alignment: alignment,
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (alignment == Alignment.centerRight) Text(label),
          const SizedBox(width: 8),
          Icon(icon),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 8),
            Text(label),
          ],
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final bool warning;

  const _MetaPill({required this.label, this.warning = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: warning
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: warning
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EnumPicker<T> extends StatelessWidget {
  final String title;
  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;

  const _EnumPicker({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ...values.map(
            (value) => ListTile(
              title: Text(labelBuilder(value)),
              trailing: value == selected
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(context, value),
            ),
          ),
        ],
      ),
    );
  }
}
