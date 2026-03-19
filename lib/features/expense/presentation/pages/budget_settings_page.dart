import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_ai_app/features/expense/presentation/providers/expense_provider.dart';

class BudgetSettingsPage extends ConsumerStatefulWidget {
  const BudgetSettingsPage({super.key});

  @override
  ConsumerState<BudgetSettingsPage> createState() => _BudgetSettingsPageState();
}

class _BudgetSettingsPageState extends ConsumerState<BudgetSettingsPage> {
  // Map temporaire pour stocker les valeurs éditées <CategoryID, Controller>
  final Map<int, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void dispose() {
    // Nettoyage des contrôleurs
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final repository = ref.read(expenseRepositoryProvider);

    // On boucle sur les contrôleurs pour sauvegarder
    for (var entry in _controllers.entries) {
      final catId = entry.key;
      final text = entry.value.text;
      final amount = double.tryParse(text) ?? 0.0;

      await repository.setBudget(catId, amount, now.month, now.year);
    }

    // Rafraîchir le provider des budgets
    ref.invalidate(budgetsProvider);

    setState(() => _isLoading = false);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Définir mes budgets"),
        actions: [TextButton(onPressed: _isLoading ? null : _saveAll, child: const Text("Enregistrer"))],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return budgetsAsync.when(
            data: (budgets) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];

                  // Initialiser le contrôleur avec la valeur existante ou 0
                  if (!_controllers.containsKey(cat.id)) {
                    final currentBudget = budgets[cat.id] ?? 0.0;
                    _controllers[cat.id] = TextEditingController(text: currentBudget.toStringAsFixed(0));
                  }

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Icône et Nom
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Icon(
                                  IconData(cat.icon ?? 0xe3a7, fontFamily: 'MaterialIcons'),
                                  color: Color(cat.color ?? 0xFF9E9E9E),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          // Champ Montant
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _controllers[cat.id],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                hintText: '0',
                                suffixText: 'FCFA',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text("Erreur: $e")),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Erreur: $e")),
      ),
    );
  }
}
