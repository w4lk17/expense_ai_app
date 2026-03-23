import 'package:expense_ai_app/core/widgets/animated_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../widgets/add_expense_sheet.dart';

class ExpenseListPage extends ConsumerStatefulWidget {
  const ExpenseListPage({super.key});

  @override
  ConsumerState<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends ConsumerState<ExpenseListPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;

    // Logique de direction
    if (currentOffset > _lastScrollOffset && currentOffset > 50) {
      // On descend ET on a dépassé le haut -> Cacher
      if (_showFab) setState(() => _showFab = false);
    } else if (currentOffset < _lastScrollOffset) {
      // On remonte -> Montrer
      if (!_showFab) setState(() => _showFab = true);
    }

    // Mémoriser la position pour le prochain tour
    _lastScrollOffset = currentOffset;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseListProvider);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');

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
            controller: _scrollController,
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final item = expenses[index];
              final expense = item.expense;
              final category = item.category;

              // 1. WIDGET DISMISSIBLE (Pour supprimer au swipe)
              return AnimatedListItem(
                index: index,
                child: Dismissible(
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
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: category != null ? Color(category.color ?? 0xFF9E9E9E) : Colors.grey,
                          child: Icon(
                            category != null
                                ? IconData(category.icon ?? 0xe3a7, fontFamily: 'MaterialIcons')
                                : Icons.attach_money,
                            color: Colors.white,
                          ),
                        ),
                        // Indicateur "Cloud" si synchronisé, "Cloud Off" si non
                        if (!expense.isSynced)
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: Icon(Icons.cloud_off, size: 14, color: Colors.red),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(expense.description ?? 'Dépense')),
                        if (expense.isRecurring)
                          Icon(Icons.cable, size: 16, color: Colors.grey), // Icône récurrent
                      ],
                    ),
                    subtitle: Text(
                      '${category?.name ?? "Non classé"} • ${DateFormat('dd/MM/yyyy').format(expense.date)}',
                    ),
                    trailing: Text(
                      currencyFormat.format(expense.amount),
                      style: TextStyle(
                        color: expense.isIncome ? Colors.blue : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _showFab ? Offset.zero : const Offset(0, 2), // Glissement vers le bas
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showFab ? 1.0 : 0.0,
          child: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const AddExpenseSheet(),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
