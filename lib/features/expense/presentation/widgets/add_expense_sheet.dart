import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expense_ai_app/features/expense/data/datasources/database.dart'; // Pour ExpensesCompanion

import '../providers/expense_provider.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null) return;

      // Création de l'objet Companion pour Drift
      final expense = ExpensesCompanion.insert(
        amount: drift.Value(amount).value,
        description: drift.Value(_descController.text),
        date: _selectedDate,
        // Pour l'instant, pas de catégorie sélectionnée (null)
        categoryId: const drift.Value.absent(),
      );

      // Appel au repository via le provider
      await ref.read(expenseRepositoryProvider).addExpense(expense);

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Gestion du clavier
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nouvelle Dépense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            // Sélection de date simple
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
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Enregistrer'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
