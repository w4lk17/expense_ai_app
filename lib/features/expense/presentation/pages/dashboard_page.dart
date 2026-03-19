import 'package:expense_ai_app/core/providers/theme_provider.dart';
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:expense_ai_app/features/expense/presentation/pages/budget_settings_page.dart';
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
  double _budgetLimit = 0.0;

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
    buffer.writeln("Total du mois: ${totalMonth.toStringAsFixed(2)} FCFA");
    buffer.writeln("Budget limite: ${_budgetLimit.toStringAsFixed(2)} FCFA");
    expensesByCategory.forEach((cat, amount) {
      buffer.writeln("- ${cat.name}: ${amount.toStringAsFixed(2)} FCFA");
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
    // on reccupere les budgets
    final budgetsAsync = ref.watch(budgetsProvider);

    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: ' FCFA');
    final expensesAsync = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BudgetSettingsPage()));
            },
          ),
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (_) => budgetsAsync.when(
          // On imbrique la vérification des budgets
          data: (budgetsMap) {
            // Calcul du budget total (somme de tous les budgets définis)
            _budgetLimit = budgetsMap.values.fold(0.0, (sum, item) => sum + item);

            // Calcul de la progression
            final double progress = _budgetLimit > 0 ? (totalMonth / _budgetLimit) : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. CARTE TOTALE (Dynamique)
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Solde du mois",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                  fontSize: 16,
                                ),
                              ),
                              if (_budgetLimit == 0)
                                Text(
                                  "Pas de budget défini",
                                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.error),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(totalMonth),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // NOUVEAU : Affichage du budget total défini
                          if (_budgetLimit > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Budget Total",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(_budgetLimit),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_budgetLimit > 0) ...[
                            // Afficher la barre seulement si un budget existe
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                                color: progress >= 1.0
                                    ? Colors.red.shade700
                                    : Theme.of(context).colorScheme.onPrimaryContainer,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              progress >= 1.0
                                  ? "Budget dépassé ! (${currencyFormat.format(totalMonth - _budgetLimit)} de trop)"
                                  : "Reste à dépenser: ${currencyFormat.format(_budgetLimit - totalMonth)}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 2. ALERTE BUDGET
                  if (_budgetLimit > 0 && totalMonth > _budgetLimit)
                    Card(
                      margin: const EdgeInsets.only(top: 16, bottom: 16),
                      color: Colors.red.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Attention ! Vous avez dépassé votre budget mensuel ($_budgetLimit FCFA).",
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                  // 3. CARTE ANALYSE IA
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary),
                              const SizedBox(width: 8),
                              Text(
                                "Conseil de l'IA",
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isLoadingAdvice)
                            const Center(child: CircularProgressIndicator())
                          else if (_aiAdvice != null)
                            Text(_aiAdvice!, style: Theme.of(context).textTheme.bodyMedium)
                          else
                            Text(
                              "Obtenez une analyse personnalisée de vos dépenses.",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          const SizedBox(height: 16),
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

                  const SizedBox(height: 32),

                  // 4. GRAPHIQUE
                  Text(
                    "Répartition par catégorie",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (expensesByCategory.isEmpty)
                    SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          "Aucune dépense ce mois-ci",
                          style: TextStyle(color: Theme.of(context).colorScheme.outline),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: showingSections(expensesByCategory),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Erreur budgets: $e")),
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
          radius: 80, // Un peu plus petit pour le style donut
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    });
    return sections;
  }
}
