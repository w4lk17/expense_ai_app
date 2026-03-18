import 'package:expense_ai_app/core/providers/theme_provider.dart';
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import 'package:expense_ai_app/features/ai_advisor/data/services/ai_cache_service.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String? _aiAdvice;
  bool _isLoadingAdvice = false;
  final AiCacheService _cacheService = AiCacheService();

  Future<void> _getAnalysis() async {
    final cached = await _cacheService.getTodayAnalysis();
    if (cached != null) {
      setState(() {
        _aiAdvice = cached;
      });
      return;
    }

    setState(() => _isLoadingAdvice = true);

    final expensesByCategory = ref.read(expensesByCategoryProvider);
    final totalMonth = ref.read(totalMonthProvider);

    final buffer = StringBuffer();
    buffer.writeln("Total du mois: ${totalMonth.toStringAsFixed(2)}FCFA");
    expensesByCategory.forEach((cat, amount) {
      buffer.writeln("- ${cat.name}: ${amount.toStringAsFixed(2)}FCFA");
    });

    final advice = await ref.read(expenseRepositoryProvider).analyzeExpenses(buffer.toString());

    if (advice != null) {
      await _cacheService.saveAnalysis(advice);
      setState(() {
        _aiAdvice = advice;
      });
    } else {
      setState(() {
        _aiAdvice = "Erreur de connexion à l'IA.";
      });
    }

    setState(() => _isLoadingAdvice = false);
  }

  @override
  Widget build(BuildContext context) {
    final expensesByCategory = ref.watch(expensesByCategoryProvider);
    final totalMonth = ref.watch(totalMonthProvider);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
    final expensesAsync = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: Icon(
              // Si le thème appliqué est sombre, on montre le soleil
              Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Affichage du total du mois
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total dépensé ce mois', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(totalMonth),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
              // Carte Alerte si dépassement de budget
              if (totalMonth > 1000)
                Card(
                  margin: const EdgeInsets.only(top: 16, bottom: 0),
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Attention ! Vous avez dépassé votre budget mensuel virtuel (1000 FCFA).",
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Carte de l'IA Advisor
              Card(
                elevation: 4,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          const SizedBox(width: 8),
                          Text(
                            "Conseil de l'IA",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingAdvice)
                        const Center(child: CircularProgressIndicator())
                      else if (_aiAdvice != null)
                        Text(_aiAdvice!, style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer))
                      else
                        Text(
                          "Obtenez une analyse personnalisée de vos dépenses.",
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _getAnalysis,
                          icon: const Icon(Icons.analytics),
                          label: const Text("Analyser mon mois"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Répartition par catégorie', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (expensesByCategory.isEmpty)
                const SizedBox(height: 150, child: Center(child: Text("Aucune dépense à afficher")))
              else
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: showingSections(expensesByCategory),
                    ),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  List<PieChartSectionData> showingSections(Map<Category, double> data) {
    final List<PieChartSectionData> sections = [];
    data.forEach((category, total) {
      final color = Color(category.color ?? 0xFF607D8B);
      sections.add(
        PieChartSectionData(
          color: color,
          value: total,
          title: '${category.name}\n${total.toStringAsFixed(0)} FCFA',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      );
    });
    return sections;
  }
}
