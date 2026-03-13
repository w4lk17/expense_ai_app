import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../widgets/add_expense_sheet.dart';

class ExpenseListPage extends ConsumerWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On écoute le flux des dépenses
    final expensesAsync = ref.watch(expenseListProvider);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Dépenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Placeholder pour plus tard
            },
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              child: Text(
                'Aucune dépense enregistrée.\nCliquez sur + pour commencer.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final item = expenses[index]; // C'est maintenant un ExpenseWithCategory
              final expense = item.expense;
              final category = item.category;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: category != null ? Color(category.color ?? 0xFF9E9E9E) : Colors.grey,
                  child: Icon(
                    category != null
                        ? IconData(category.icon ?? 0xe3a7, fontFamily: 'MaterialIcons')
                        : Icons.attach_money,
                    color: Colors.white,
                  ),
                ),
                title: Text(expense.description ?? 'Dépense'),
                subtitle: Text(
                  '${category?.name ?? "Non classé"} • ${DateFormat('dd/MM/yyyy').format(expense.date)}',
                ),
                trailing: Text(
                  currencyFormat.format(expense.amount),
                  style: const TextStyle(
                    color: Colors.red, // On verra plus tard pour la couleur dynamique (Revenus vs Dépenses)
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onLongPress: () {
                  // Suppression (optionnelle pour l'instant)
                  // ref.read(expenseRepositoryProvider).deleteExpense(expense);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Permet au formulaire de prendre la hauteur nécessaire
            builder: (context) => const AddExpenseSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
