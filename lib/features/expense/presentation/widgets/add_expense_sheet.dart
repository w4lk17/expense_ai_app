import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:expense_ai_app/core/providers/connectivity_provider.dart';
import 'package:expense_ai_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:expense_ai_app/features/expense/presentation/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final Expense? expenseToEdit;
  final bool initialIsIncome;

  const AddExpenseSheet({
    super.key,
    this.expenseToEdit,
    this.initialIsIncome = false,
  });

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _paymentController = TextEditingController();
  Timer? _debounce;

  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  bool _isSaving = false;
  bool _isRecurring = false;
  bool _isIncome = false;
  bool _didManuallyPickCategory = false;
  String _recurrenceInterval = 'monthly';
  String? _suggestedCategoryName;

  bool get isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expenseToEdit;
    _isIncome = expense?.isIncome ?? widget.initialIsIncome;
    _isRecurring = expense?.isRecurring ?? false;
    _recurrenceInterval = expense?.recurrenceInterval ?? 'monthly';

    if (expense != null) {
      _amountController.text = expense.amount.toStringAsFixed(2);
      _descController.text = expense.description ?? '';
      _paymentController.text = expense.paymentMethod ?? '';
      _selectedDate = expense.date;
    }

    _descController.addListener(_handleDescriptionChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amountController.dispose();
    _descController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  void _handleDescriptionChanged() {
    _debounce?.cancel();
    final text = _descController.text.trim();
    if (text.isEmpty) {
      if (mounted) setState(() => _suggestedCategoryName = null);
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 350),
      _suggestCategorySilently,
    );
  }

  Future<void> _suggestCategorySilently() async {
    final text = _descController.text.trim();
    if (text.isEmpty) return;

    final suggestion = await ref
        .read(expenseRepositoryProvider)
        .suggestCategory(text);
    if (!mounted || suggestion == null) return;

    final categories = ref.read(categoryListProvider).value ?? [];
    Category? match;
    for (final category in categories) {
      if (category.name.toLowerCase() == suggestion.toLowerCase()) {
        match = category;
        break;
      }
    }

    setState(() {
      _suggestedCategoryName = suggestion;
      if (!_didManuallyPickCategory && match != null) {
        _selectedCategory = match;
      }
    });
  }

  DateTime? _nextRecurrenceDate() {
    if (!_isRecurring) return null;

    if (_recurrenceInterval == 'weekly') {
      return _selectedDate.add(const Duration(days: 7));
    }

    return DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      _selectedDate.day,
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    setState(() => _isSaving = true);
    final nextRecurrence = _nextRecurrenceDate();

    if (isEditing) {
      final updatedExpense = widget.expenseToEdit!.copyWith(
        amount: amount,
        description: drift.Value(_descController.text.trim()),
        categoryId: drift.Value(_selectedCategory?.id),
        date: _selectedDate,
        paymentMethod: drift.Value(
          _paymentController.text.trim().isEmpty
              ? null
              : _paymentController.text.trim(),
        ),
        isRecurring: _isRecurring,
        isIncome: _isIncome,
        recurrenceInterval: drift.Value(
          _isRecurring ? _recurrenceInterval : 'monthly',
        ),
        nextRecurrenceDate: drift.Value(nextRecurrence),
        isSynced: false,
      );
      await ref.read(expenseRepositoryProvider).updateExpense(updatedExpense);
    } else {
      final expense = ExpensesCompanion.insert(
        amount: amount,
        date: _selectedDate,
        description: drift.Value(_descController.text.trim()),
        categoryId: drift.Value(_selectedCategory?.id),
        paymentMethod: drift.Value(
          _paymentController.text.trim().isEmpty
              ? null
              : _paymentController.text.trim(),
        ),
        isIncome: drift.Value(_isIncome),
        isRecurring: drift.Value(_isRecurring),
        recurrenceInterval: drift.Value(
          _isRecurring ? _recurrenceInterval : 'monthly',
        ),
        nextRecurrenceDate: drift.Value(nextRecurrence),
      );
      await ref.read(expenseRepositoryProvider).addExpense(expense);
    }

    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(expenseRepositoryProvider).syncExpenses(user.id);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoryListProvider);
    final recentDescriptions = ref.watch(recentDescriptionsProvider);
    final isOffline =
        ref.watch(connectivityProvider) == ConnectionStatus.offline;

    if (isEditing && _selectedCategory == null && categoriesAsync.hasValue) {
      final categories = categoriesAsync.value!;
      final categoryId = widget.expenseToEdit?.categoryId;
      if (categoryId != null) {
        for (final category in categories) {
          if (category.id == categoryId) {
            _selectedCategory = category;
            break;
          }
        }
      }
    }

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit transaction' : 'New transaction',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fast entry first. Details can wait.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        SegmentedButton<bool>(
                          selected: {_isIncome},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            setState(() => _isIncome = selection.first);
                          },
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              icon: Icon(Icons.arrow_upward),
                              label: Text('Expense'),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              icon: Icon(Icons.arrow_downward),
                              label: Text('Income'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: theme.textTheme.headlineMedium,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: 'FCFA ',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter an amount'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: 'Description or merchant',
                            hintText: 'Uber, Carrefour, Salary...',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        categoriesAsync.when(
                          data: (categories) {
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categories.map((category) {
                                final selected =
                                    _selectedCategory?.id == category.id;
                                final isSuggested =
                                    _suggestedCategoryName?.toLowerCase() ==
                                    category.name.toLowerCase();
                                return FilterChip(
                                  selected: selected,
                                  avatar: isSuggested
                                      ? const Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 16,
                                        )
                                      : null,
                                  label: Text(category.name),
                                  onSelected: (_) {
                                    setState(() {
                                      _didManuallyPickCategory = true;
                                      _selectedCategory = category;
                                    });
                                  },
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(),
                          ),
                          error: (error, _) =>
                              Text('Unable to load categories: $error'),
                        ),
                        if (_suggestedCategoryName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'AI suggestion: $_suggestedCategoryName',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (recentDescriptions.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text('Use again', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: recentDescriptions.map((description) {
                              return ActionChip(
                                label: Text(description),
                                onPressed: () =>
                                    _descController.text = description,
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          title: Text(
                            'Details',
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            'Date, recurrence, and payment method',
                            style: theme.textTheme.bodyMedium,
                          ),
                          children: [
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 3650),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                ),
                                child: Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Recurring transaction'),
                              subtitle: const Text(
                                'Useful for rent, salary, subscriptions, or utilities',
                              ),
                              value: _isRecurring,
                              onChanged: (value) =>
                                  setState(() => _isRecurring = value),
                            ),
                            if (_isRecurring) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Monthly'),
                                    selected: _recurrenceInterval == 'monthly',
                                    onSelected: (_) => setState(
                                      () => _recurrenceInterval = 'monthly',
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Weekly'),
                                    selected: _recurrenceInterval == 'weekly',
                                    onSelected: (_) => setState(
                                      () => _recurrenceInterval = 'weekly',
                                    ),
                                  ),
                                  const Chip(label: Text('Custom later')),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _paymentController,
                              decoration: const InputDecoration(
                                labelText: 'Payment method',
                                hintText: 'Cash, bank card, mobile money...',
                                prefixIcon: Icon(Icons.credit_card_rounded),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (isOffline)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cloud_off_rounded,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'You are offline. Saving now keeps this transaction local until the next sync.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveExpense,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Save changes' : 'Save transaction'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
