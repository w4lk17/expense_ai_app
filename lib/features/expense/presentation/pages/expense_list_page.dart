import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../widgets/add_expense_sheet.dart';

class ExpenseListPage extends ConsumerWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Dépenses')),
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
              final item = expenses[index];
              final expense = item.expense;
              final category = item.category;

              // 1. WIDGET DISMISSIBLE (Pour supprimer au swipe)
              return Dismissible(
                key: Key(expense.id.toString()), // Clé unique obligatoire
                direction: DismissDirection.endToStart, // Swipe de droite à gauche
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  // Confirmation avant suppression
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirmer"),
                        content: const Text("Voulez-vous supprimer cette dépense ?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Annuler"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  ref.read(expenseRepositoryProvider).deleteExpense(expense);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dépense supprimée")));
                },

                // 2. LISTILE (Pour affichage et modification)
                child: ListTile(
                  onTap: () {
                    // Clic pour modifier
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => AddExpenseSheet(expenseToEdit: expense),
                    );
                  },
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
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
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
            isScrollControlled: true,
            builder: (context) => const AddExpenseSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
