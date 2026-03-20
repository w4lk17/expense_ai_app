// lib/features/expense/domain/repositories/expense_repository.dart
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';

abstract class ExpenseRepository {
  Stream<List<ExpenseWithCategory>> watchAllExpensesWithCategory();
  Future<void> addExpense(ExpensesCompanion expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(Expense expense);
  Future<void> syncExpenses(String userId);
  Future<String?> analyzeExpenses(String summary);
  Future<List<Category>> getAllCategories();
  Future<String?> suggestCategory(String description);
  Future<void> setBudget(int categoryId, double amount, int month, int year);
  Future<Map<int, double>> getBudgetsForCurrentMonth();
  Future<List<Expense>> getAllExpenses();
}
