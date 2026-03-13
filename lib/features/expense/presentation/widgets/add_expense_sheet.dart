import 'package:expense_ai_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import '../providers/expense_provider.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final Expense? expenseToEdit; // Nouveau paramètre optionnel

  const AddExpenseSheet({super.key, this.expenseToEdit});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  bool get isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    // Si on est en mode édition, on pré-remplit les champs
    if (isEditing) {
      final expense = widget.expenseToEdit!;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _descController.text = expense.description ?? '';
      _selectedDate = expense.date;
      // Pour la catégorie, on doit la retrouver dans la liste (chargée asynchrone)
      // On verra ça dans le build
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null) return;

      if (isEditing) {
        // MODE UPDATE
        final updatedExpense = widget.expenseToEdit!.copyWith(
          amount: amount,
          description: drift.Value(_descController.text),
          date: _selectedDate,
          categoryId: drift.Value(_selectedCategory?.id),
        );
        await ref.read(expenseRepositoryProvider).updateExpense(updatedExpense);
      } else {
        // MODE CREATE
        final expense = ExpensesCompanion.insert(
          amount: amount,
          description: drift.Value(_descController.text),
          date: _selectedDate,
          categoryId: drift.Value(_selectedCategory?.id),
        );
        await ref.read(expenseRepositoryProvider).addExpense(expense);

        // TENTER LA SYNC IMMEDIATE
        final user = ref.read(currentUserProvider);
        if (user != null) {
          await ref.read(expenseRepositoryProvider).syncExpenses(user.id);
        }
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);

    // Si on est en édition et que la liste des catégories est chargée,
    // on sélectionne la catégorie de la dépense
    if (isEditing && _selectedCategory == null && categoriesAsync.hasValue) {
      final cats = categoriesAsync.value!;
      final currentCatId = widget.expenseToEdit!.categoryId;
      if (currentCatId != null) {
        _selectedCategory = cats.firstWhere((c) => c.id == currentCatId, orElse: () => cats.first);
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Modifier la dépense' : 'Nouvelle Dépense',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Montant', prefixIcon: Icon(Icons.euro)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Entrez un montant' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) {
                return DropdownButtonFormField<Category>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Catégorie', prefixIcon: Icon(Icons.category)),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat.name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Erreur catégories: $e'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Date: '),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isEditing ? Colors.orange : null, // Couleur différente si édition
              ),
              child: Text(isEditing ? 'Mettre à jour' : 'Enregistrer'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
