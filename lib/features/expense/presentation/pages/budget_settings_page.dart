import 'package:expense_ai_app/features/expense/presentation/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetSettingsPage extends ConsumerStatefulWidget {
  const BudgetSettingsPage({super.key});

  @override
  ConsumerState<BudgetSettingsPage> createState() => _BudgetSettingsPageState();
}

class _BudgetSettingsPageState extends ConsumerState<BudgetSettingsPage> {
  final Map<int, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final repository = ref.read(expenseRepositoryProvider);

    for (final entry in _controllers.entries) {
      final categoryId = entry.key;
      final amount = double.tryParse(entry.value.text.trim()) ?? 0.0;
      await repository.setBudget(categoryId, amount, now.month, now.year);
    }

    ref.invalidate(budgetsProvider);
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Budgets updated.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoryListProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit budgets'),
        actions: [
          IconButton(
            onPressed: _isLoading
                ? null
                : () {
                    for (final controller in _controllers.values) {
                      controller.text = '0';
                    }
                    setState(() {});
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isLoading ? null : _saveAll,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return budgetsAsync.when(
            data: (budgets) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly category limits',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use budgets to power safe-to-spend guidance and early risk warnings.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...categories.map((category) {
                    final currentBudget = budgets[category.id] ?? 0.0;
                    _controllers.putIfAbsent(
                      category.id,
                      () => TextEditingController(
                        text: currentBudget.toStringAsFixed(0),
                      ),
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(
                              category.color ?? 0xFFE7DFD1,
                            ),
                            child: Icon(
                              IconData(
                                category.icon ?? Icons.category.codePoint,
                                fontFamily: 'MaterialIcons',
                              ),
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              category.name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: TextField(
                              controller: _controllers[category.id],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                hintText: '0',
                                suffixText: 'FCFA',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Budget load failed: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Categories failed: $error')),
      ),
    );
  }
}
