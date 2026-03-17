import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String? _aiAdvice;
  bool _isLoadingAdvice = false;

  Future<void> _getAnalysis() async {
    setState(() => _isLoadingAdvice = true);

    // 1. Récupérer les données
    final expensesByCategory = ref.read(expensesByCategoryProvider);
    final totalMonth = ref.read(totalMonthProvider);

    // 2. Formater le résumé pour l'IA
    final buffer = StringBuffer();
    buffer.writeln("Total du mois: ${totalMonth.toStringAsFixed(2)}FCFA");
    expensesByCategory.forEach((cat, amount) {
      buffer.writeln("- ${cat.name}: ${amount.toStringAsFixed(2)}FCFA");
    });

    // 3. Appeler l'IA
    final advice = await ref.read(expenseRepositoryProvider).analyzeExpenses(buffer.toString());

    setState(() {
      _aiAdvice = advice ?? "Impossible de générer l'analyse pour le moment.";
      _isLoadingAdvice = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final expensesByCategory = ref.watch(expensesByCategoryProvider);
    final totalMonth = ref.watch(totalMonthProvider);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: SingleChildScrollView(
        // Permet le scroll si l'écran est petit
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARTE TOTAL
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
            const SizedBox(height: 16),

            // CARTE ANALYSE IA (NOUVEAU)
            Card(
              elevation: 4,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          "Conseil de l'IA",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingAdvice)
                      const Center(child: CircularProgressIndicator())
                    else if (_aiAdvice != null)
                      Text(_aiAdvice!)
                    else
                      const Text("Obtenez une analyse personnalisée de vos dépenses."),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _getAnalysis,
                        icon: const Icon(Icons.analytics),
                        label: const Text("Analyser mon mois"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // GRAPHIQUE
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
          title: '${category.name}\n${total.toStringAsFixed(0)}FCFA',
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
