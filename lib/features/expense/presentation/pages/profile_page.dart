import 'dart:io';

import 'package:expense_ai_app/core/constants/api_keys.dart';
import 'package:expense_ai_app/core/providers/connectivity_provider.dart';
import 'package:expense_ai_app/core/providers/theme_provider.dart';
import 'package:expense_ai_app/features/ai_advisor/presentation/providers/ai_provider_settings.dart';
import 'package:expense_ai_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_ai_app/features/expense/presentation/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _exportToCsv(BuildContext context, WidgetRef ref) async {
    final expenses = ref.read(expenseListProvider).value ?? [];
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses available to export.')),
      );
      return;
    }

    final buffer = StringBuffer('Date,Description,Category,Amount,Type\n');
    for (final item in expenses) {
      final expense = item.expense;
      buffer.writeln(
        '${DateFormat('dd/MM/yyyy').format(expense.date)},"${expense.description ?? ''}",'
        '"${item.category?.name ?? 'Unsorted'}",${expense.amount},${expense.isIncome ? 'income' : 'expense'}',
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final filename =
        'expense_ai_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$filename');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Expense AI export'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final aiProvider = ref.watch(aiProviderSettingsProvider);
    final pendingSync = ref.watch(pendingSyncCountProvider);
    final connection = ref.watch(connectivityProvider);
    final summary = ref.watch(monthlyFinanceSnapshotProvider);
    final budgetAlerts = ref.watch(budgetAlertsControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        Text('Profile', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Preferences, sync state, and exports.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
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
                currentUser?.email ?? 'Signed in',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ProfileBadge(
                      label: connection == ConnectionStatus.offline
                          ? 'Offline'
                          : 'Online',
                      icon: connection == ConnectionStatus.offline
                          ? Icons.cloud_off_rounded
                          : Icons.cloud_done_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProfileBadge(
                      label: pendingSync > 0
                          ? '$pendingSync pending'
                          : 'All synced',
                      icon: pendingSync > 0
                          ? Icons.sync_problem_rounded
                          : Icons.check_circle_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ProfileBadge(
                label:
                    'Safe to spend ${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(summary.safeToSpend)}',
                icon: Icons.wallet_rounded,
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
              Text('Budget alerts', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Send local alerts when a category budget crosses 70%, 90%, or 100%.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Local budget notifications'),
                subtitle: const Text(
                  'In-app alerts remain visible even if notifications are off.',
                ),
                value: budgetAlerts.notificationsEnabled,
                onChanged: (value) {
                  ref
                      .read(budgetAlertsControllerProvider.notifier)
                      .setNotificationsEnabled(value);
                },
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
              Text('Appearance', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Theme'),
                subtitle: const Text(
                  'Switch between calm light and dark modes',
                ),
                trailing: IconButton(
                  onPressed: () =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                ),
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
              Text('AI assistance', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Choose your assistant engine. Core flows remain offline-safe.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AiProvider.values.map((provider) {
                  final selected = provider == aiProvider;
                  return ChoiceChip(
                    label: Text(aiProviderLabel(provider)),
                    selected: selected,
                    onSelected: (_) => ref
                        .read(aiProviderSettingsProvider.notifier)
                        .setProvider(provider),
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
              Text('Data', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Export monthly CSV'),
                subtitle: const Text(
                  'Share a portable snapshot of your transactions',
                ),
                onTap: () => _exportToCsv(context, ref),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sign out'),
                subtitle: const Text(
                  'Keep local data on device, close the cloud session',
                ),
                onTap: () => ref.read(authRepositoryProvider).signOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ProfileBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
