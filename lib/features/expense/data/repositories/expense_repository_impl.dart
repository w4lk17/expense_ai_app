// lib/features/expense/data/repositories/expense_repository_impl.dart
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:expense_ai_app/features/expense/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final AppDatabase _db;

  ExpenseRepositoryImpl(this._db);

  @override
  Stream<List<Expense>> watchAllExpenses() {
    return _db.watchAllExpenses();
  }

  @override
  Future<void> addExpense(ExpensesCompanion expense) {
    return _db.insertExpense(expense);
  }

  @override
  Future<void> deleteExpense(Expense expense) {
    return _db.deleteExpense(expense);
  }
}
