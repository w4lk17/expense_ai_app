// lib/features/expense/data/repositories/expense_repository_impl.dart
import 'package:expense_ai_app/features/ai_advisor/data/services/ai_service_factory.dart';
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:expense_ai_app/features/expense/domain/repositories/expense_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final OpenAIService _aiService;

  ExpenseRepositoryImpl(this._db, this._supabase, this._aiService);

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
    try {
      final unsyncedExpenses = await _db.getUnsyncedExpenses();
      if (unsyncedExpenses.isEmpty) return;

      for (var expense in unsyncedExpenses) {
        try {
          // 1. Envoi vers Supabase
          await _supabase.from('expenses').insert({
            'user_id': userId,
            'amount': expense.amount,
            'description': expense.description,
            'category_id': expense.categoryId,
            'date': expense.date.toIso8601String(),
            'payment_method': expense.paymentMethod,
            'created_at': expense.createdAt.toIso8601String(),
            'is_recurring': expense.isRecurring,
            'recurrence_interval': expense.recurrenceInterval,
            'next_recurrence_date': expense.nextRecurrenceDate?.toIso8601String(),
          });

          // 2. Mise à jour du flag local : C'est crucial pour faire disparaitre l'icône "Cloud Off"
          await _db.updateSyncStatus(expense.id, true);
        } catch (e) {
          // On continue quand même pour voir si les autres passent
        }
      }
    } catch (e) {
      // print("Erreur globale de sync: $e");
    }
  }

  @override
  Future<String?> suggestCategory(String description) async {
    return await _aiService.suggestCategory(description);
  }

  @override
  Future<String?> analyzeExpenses(String summary) async {
    return await _aiService.analyzeExpenses(summary);
  }
}
