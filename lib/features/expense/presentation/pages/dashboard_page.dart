import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesByCategory = ref.watch(expensesByCategoryProvider);
    final totalMonth = ref.watch(totalMonthProvider);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: Padding(
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
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red, // On verra plus tard pour gérer revenus/dépenses
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // TITRE GRAPHIQUE
            Text('Répartition par catégorie', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // GRAPHIQUE
            if (expensesByCategory.isEmpty)
              const Expanded(child: Center(child: Text("Aucune dépense à afficher")))
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

  // Fonction pour générer les sections du camembert
  List<PieChartSectionData> showingSections(Map<Category, double> data) {
    final List<PieChartSectionData> sections = [];

    data.forEach((category, total) {
      final color = Color(category.color ?? 0xFF607D8B);
      sections.add(
        PieChartSectionData(
          color: color,
          value: total,
          title: '${category.name}\n${total.toStringAsFixed(0)}€',
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
