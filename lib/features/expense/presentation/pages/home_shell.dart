import 'package:expense_ai_app/core/providers/connectivity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_ai_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_ai_app/features/expense/presentation/providers/expense_provider.dart';
import 'dashboard_page.dart';
import 'expense_list_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [DashboardPage(), ExpenseListPage()];

  @override
  void initState() {
    super.initState();
    // On lance la sync juste après que le widget soit construit
    Future.microtask(() => _syncData());
  }

  Future<void> _syncData() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        // On force la tentative de sync des données en attente
        await ref.read(expenseRepositoryProvider).syncExpenses(user.id);
        // Si ça marche, Riverpod mettra à jour la liste automatiquement (Stream)
      } catch (e) {
        // print("Erreur sync au démarrage: $e"); // Normal si offline
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectivityProvider);

    return Scaffold(
      // utiliser animatedswitcher pour une transition fluide entre les pages
      body: Column(
        children: [
          // Banner de offline
          if (connectionStatus == ConnectionStatus.offline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const Center(
                child: Text(
                  "⚠️ Mode Hors Ligne",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _pages[_currentIndex]),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: 'Historique'),
        ],
      ),
    );
  }
}
