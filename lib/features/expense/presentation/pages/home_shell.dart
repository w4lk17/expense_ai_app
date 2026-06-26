import 'package:expense_ai_app/core/providers/connectivity_provider.dart';
import 'package:expense_ai_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_ai_app/features/expense/presentation/pages/activity_page.dart';
import 'package:expense_ai_app/features/expense/presentation/pages/home_page.dart';
import 'package:expense_ai_app/features/expense/presentation/pages/plan_page.dart';
import 'package:expense_ai_app/features/expense/presentation/pages/profile_page.dart';
import 'package:expense_ai_app/features/expense/presentation/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;
  ProviderSubscription<List<CategoryBudgetHealth>>? _budgetHealthSubscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _syncData();
      await ref.read(budgetAlertsControllerProvider.notifier).initialize();
    });

    _budgetHealthSubscription = ref.listenManual<List<CategoryBudgetHealth>>(
      categoryBudgetHealthProvider,
      (_, _) {
        ref.read(budgetAlertsControllerProvider.notifier).reconcile();
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _budgetHealthSubscription?.close();
    super.dispose();
  }

  Future<void> _syncData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await ref.read(expenseRepositoryProvider).syncExpenses(user.id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectivityProvider);

    final pages = [
      HomePage(
        onOpenProfile: () => setState(() => _currentIndex = 3),
        onOpenPlan: () => setState(() => _currentIndex = 2),
      ),
      const ActivityPage(),
      const PlanPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (connectionStatus == ConnectionStatus.offline)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Offline mode active. New entries stay local and sync later.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
