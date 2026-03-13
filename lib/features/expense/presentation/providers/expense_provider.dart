// lib/features/expense/presentation/providers/expense_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_ai_app/core/providers/database_provider.dart';
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:expense_ai_app/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:expense_ai_app/features/expense/domain/repositories/expense_repository.dart';

// Provider pour le Repository
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepositoryImpl(db);
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
