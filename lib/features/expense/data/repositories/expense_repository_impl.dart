// lib/features/expense/data/repositories/expense_repository_impl.dart
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:expense_ai_app/features/expense/domain/repositories/expense_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  ExpenseRepositoryImpl(this._db, this._supabase);

  @override
  Stream<List<ExpenseWithCategory>> watchAllExpensesWithCategory() {
    return _db.watchAllExpensesWithCategory();
  }

  @override
  Future<List<Category>> getAllCategories() {
    return _db.getAllCategories();
  }

  @override
  Future<void> addExpense(ExpensesCompanion expense) {
    return _db.insertExpense(expense);
  }

 @override
  Future<void> updateExpense(Expense expense) {
    return _db.updateExpense(expense);
  }

  @override
  Future<void> deleteExpense(Expense expense) {
    return _db.deleteExpense(expense);
  }

  @override
  Future<void> syncExpenses(String userId) async {
    // 1. Récupérer les dépenses locales non synchronisées
    // (Il faut ajouter une méthode DAO pour ça : getUnsyncedExpenses)
    final unsyncedExpenses = await _db.getUnsyncedExpenses();

    if (unsyncedExpenses.isEmpty) return;

    // 2. Les envoyer à Supabase
    for (var expense in unsyncedExpenses) {
      try {
        await _supabase.from('expenses').insert({
          'user_id': userId,
          'amount': expense.amount,
          'description': expense.description,
          'category_id': expense.categoryId,
          'date': expense.date.toIso8601String(),
          'payment_method': expense.paymentMethod,
          'created_at': expense.createdAt.toIso8601String(),
        });

        // 3. Marquer comme synchronisé en local
        await _db.updateSyncStatus(expense.id, true);
      } catch (e) {
        print('Erreur sync dépense ${expense.id}: $e');
        // On continue même si erreur (on réessaiera plus tard)
      }
    }
  }
}
