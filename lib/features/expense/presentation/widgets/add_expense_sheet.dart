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
  bool _isAiLoading = false;

  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  bool get isEditing => widget.expenseToEdit != null;
  bool _isRecurring = false;

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

      // --- 1. CALCUL DE LA RÉCURRENCE ---
      DateTime? nextRecurrence;
      if (_isRecurring && !isEditing) {
        // Si c'est une nouvelle dépense récurrente, on calcule la prochaine échéance (+1 mois)
        nextRecurrence = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
      }

      // --- 2. EXÉCUTION ---
      if (isEditing) {
        // MODE UPDATE (Modification)
        // copyWith attend des valeurs BRUTES (pas de drift.Value)
        final updatedExpense = widget.expenseToEdit!.copyWith(
          amount: amount,
          description: drift.Value(_descController.text),
          date: _selectedDate, // DateTime
          categoryId: drift.Value(_selectedCategory?.id), // int? (peut être null)
        );
        await ref.read(expenseRepositoryProvider).updateExpense(updatedExpense);
      } else {
        // MODE CREATE (Création)
        // ExpensesCompanion.insert attend :
        // - Valeurs brutes pour les champs obligatoires (amount, date)
        // - drift.Value() pour les champs optionnels
        final expense = ExpensesCompanion.insert(
          // Champs obligatoires (bruts)
          amount: amount,
          date: _selectedDate,

          // Champs optionnels (wrappés)
          description: drift.Value(_descController.text),
          categoryId: drift.Value(_selectedCategory?.id),
          isRecurring: drift.Value(_isRecurring),
          nextRecurrenceDate: drift.Value(nextRecurrence), // Sera null si pas récurrent
        );

        await ref.read(expenseRepositoryProvider).addExpense(expense);

        // TENTATIVE DE SYNCHRONISATION IMMÉDIATE
        final user = ref.read(currentUserProvider);
        if (user != null) {
          await ref.read(expenseRepositoryProvider).syncExpenses(user.id);
        }
      }

      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _suggestCategory() async {
    final text = _descController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Entrez une description d'abord (ex: 'Uber')")));
      return;
    }

    setState(() => _isAiLoading = true);

    // Appel au repository (qui utilise notre Mock pour l'instant)
    final suggestion = await ref.read(expenseRepositoryProvider).suggestCategory(text);

    setState(() => _isAiLoading = false);

    if (suggestion != null && mounted) {
      // On cherche la catégorie correspondante dans la liste
      final cats = ref.read(categoryListProvider).value;
      if (cats != null) {
        try {
          // On ignore la casse pour trouver la catégorie
          final match = cats.firstWhere((c) => c.name.toLowerCase() == suggestion.toLowerCase());
          setState(() {
            _selectedCategory = match;
          });
        } catch (e) {
          // Si l'IA renvoie une catégorie inconnue, on ignore
        }
      }
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Alignement
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Espace
                // Bouton Magique (uniquement à la création pour l'instant)
                if (!isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0), // Aligner avec le champ
                    child: IconButton(
                      icon: _isAiLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_fix_high), // Icône "Baguette Magique"
                      tooltip: 'Suggérer la catégorie (IA)',
                      onPressed: _isAiLoading ? null : _suggestCategory,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) {
                return DropdownButtonFormField<Category>(
                  initialValue: _selectedCategory,
                  hint: const Text('Sélectionner une catégorie'),
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
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Dépense récurrente (mensuelle)'),
                Switch(
                  value: _isRecurring,
                  onChanged: (val) {
                    setState(() {
                      _isRecurring = val;
                    });
                  },
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
