// lib/features/expense/presentation/providers/expense_provider.dart
import 'package:expense_ai_app/features/ai_advisor/data/services/ai_service_factory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_ai_app/core/providers/database_provider.dart';
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:expense_ai_app/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:expense_ai_app/features/expense/domain/repositories/expense_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider pour le Repository
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = Supabase.instance.client; // On récupère l'instance de Supabase
  final aiService = OpenAIService(); // instance du service OpenAI
  return ExpenseRepositoryImpl(db, supabase, aiService);
});

// Provider pour la liste des catégories (pour le dropdown)
final categoryListProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getAllCategories();
});

// Provider pour la liste des dépenses (Stream)
// L'UI écoutera ce provider pour mettre à jour la liste en temps réel
final expenseListProvider = StreamProvider<List<ExpenseWithCategory>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.watchAllExpensesWithCategory();
});

// Ce provider calcule les totaux par catégorie
final expensesByCategoryProvider = Provider<Map<Category, double>>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);

  // Si pas de données, retourne une map vide
  return expensesAsync.maybeWhen(
    data: (items) {
      final map = <Category, double>{};
      for (var item in items) {
        if (item.category != null) {
          // On additionne les montants par catégorie
          map.update(item.category!, (value) => value + item.expense.amount, ifAbsent: () => item.expense.amount);
        }
      }
      return map;
    },
    orElse: () => {},
  );
});

// Provider pour le total du mois actuel
final totalMonthProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);

  return expensesAsync.maybeWhen(
    data: (items) {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      return items
          .where((item) => item.expense.date.month == currentMonth && item.expense.date.year == currentYear)
          .fold(0.0, (sum, item) => sum + item.expense.amount);
    },
    orElse: () => 0.0,
  );
});

// Provider pour la liste des budgets (Map<CategoryID, Amount>)
final budgetsProvider = FutureProvider<Map<int, double>>((ref) async {
  return ref.watch(expenseRepositoryProvider).getBudgetsForCurrentMonth();
});
