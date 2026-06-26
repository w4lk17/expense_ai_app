import 'package:expense_ai_app/core/themes/app_theme.dart';
import 'package:expense_ai_app/features/expense/presentation/pages/budget_settings_page.dart';
import 'package:expense_ai_app/features/expense/presentation/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(monthlyFinanceSnapshotProvider);
    final budgets = ref.watch(categoryBudgetHealthProvider);
    final alerts = ref.watch(budgetAlertsControllerProvider);
    final recurring = ref.watch(upcomingRecurringProvider);
    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan ahead',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Budgets, bills, and your pacing for the month.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BudgetSettingsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit budgets'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Safe to spend', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      currency.format(summary.safeToSpend),
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _PlanStat(
                            label: 'Monthly budgets',
                            value: currency.format(summary.budgetTotal),
                          ),
                        ),
                        Expanded(
                          child: _PlanStat(
                            label: 'Upcoming bills',
                            value: currency.format(summary.upcomingBills),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (alerts.hasAlerts) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alerts', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'These categories need attention now.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      ...alerts.activeAlerts.map((alert) {
                        final color = switch (alert.level) {
                          BudgetAlertLevel.warning70 => AppTheme.amber,
                          BudgetAlertLevel.warning90 => const Color(0xFFC37B3A),
                          BudgetAlertLevel.over100 => AppTheme.coral,
                        };

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: color.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      alert.title,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      ref
                                          .read(
                                            budgetAlertsControllerProvider
                                                .notifier,
                                          )
                                          .dismissAlert(alert);
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                    tooltip: 'Dismiss',
                                  ),
                                ],
                              ),
                              Text(
                                alert.message,
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                alert.suggestion,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${currency.format(alert.spent)} / ${currency.format(alert.limit)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category budgets', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      budgets.isEmpty
                          ? 'Set at least one category budget to unlock pacing and risk warnings.'
                          : 'Watch your strongest risk signals first.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    if (budgets.isEmpty)
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BudgetSettingsPage(),
                            ),
                          );
                        },
                        child: const Text('Set budgets'),
                      )
                    else
                      Column(
                        children: budgets.map((item) {
                          final color = switch (item.status) {
                            BudgetStatus.underControl => AppTheme.moss,
                            BudgetStatus.caution => AppTheme.amber,
                            BudgetStatus.overLimit => AppTheme.coral,
                          };

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.category.name,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                    Text(
                                      '${currency.format(item.spent)} / ${currency.format(item.limit)}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: item.ratio.clamp(0.0, 1.0),
                                    minHeight: 10,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.status == BudgetStatus.overLimit
                                      ? 'Over limit. Trim this category first.'
                                      : item.status == BudgetStatus.caution
                                      ? 'Approaching the limit.'
                                      : 'On track for now.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recurring obligations',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rent, subscriptions, and bills still ahead this month.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    if (recurring.isEmpty)
                      Text(
                        'No recurring obligations are due before month-end.',
                        style: theme.textTheme.bodyLarge,
                      )
                    else
                      Column(
                        children: recurring.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.expense.description ??
                                            item.category?.name ??
                                            'Recurring expense',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Due ${DateFormat('dd MMM').format(item.expense.nextRecurrenceDate!)}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currency.format(item.expense.amount),
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _PlanStat extends StatelessWidget {
  final String label;
  final String value;

  const _PlanStat({required this.label, required this.value});

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
