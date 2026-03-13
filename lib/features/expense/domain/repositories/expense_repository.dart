// lib/features/expense/domain/repositories/expense_repository.dart
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchAllExpenses();
  Future<void> addExpense(ExpensesCompanion expense);
  Future<void> deleteExpense(Expense expense);
}
