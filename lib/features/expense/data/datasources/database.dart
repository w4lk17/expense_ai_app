import 'package:drift/drift.dart';

import '../../../../core/database/connection.dart';

part 'database.g.dart';

// 1. TABLE CATEGORIES
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get color => integer().nullable()();
  IntColumn get icon => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// 2. TABLE EXPENSES
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get paymentMethod => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

// 3. TABLE BUDGETS
// Permet de définir un plafond par catégorie et par mois
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()(); // Le montant limite du budget
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get month => integer()(); // 1 à 12
  IntColumn get year => integer()(); // ex: 2024
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Categories, Expenses, Budgets])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 2; // On incrémente la version car on ajoute une table

  // --- SEED DATA (Mission 2) ---
  // Peuple la base avec des catégories par défaut si vide
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Insertion des catégories par défaut
        await batch((b) {
          b.insertAll(categories, [
            CategoriesCompanion.insert(name: 'Alimentation', color: const Value(0xFFFF9800)),
            CategoriesCompanion.insert(name: 'Transport', color: const Value(0xFF2196F3)),
            CategoriesCompanion.insert(name: 'Logement', color: const Value(0xFF9C27B0)),
            CategoriesCompanion.insert(name: 'Loisirs', color: const Value(0xFF4CAF50)),
            CategoriesCompanion.insert(name: 'Santé', color: const Value(0xFFF44336)),
            CategoriesCompanion.insert(name: 'Autre', color: const Value(0xFF607D8B)),
          ]);
        });
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Gestion des migrations futures
        if (from < 2) {
          await m.createTable(budgets);
        }
      },
    );
  }

  // --- CATEGORIES DAO ---
  Future<int> insertCategory(CategoriesCompanion category) => into(categories).insert(category);
  Future<List<Category>> getAllCategories() => select(categories).get();
  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  // --- EXPENSES DAO ---
  Future<int> insertExpense(ExpensesCompanion expense) => into(expenses).insert(expense);
  Future<int> deleteExpense(Expense expense) => delete(expenses).delete(expense);
  Stream<List<Expense>> watchAllExpenses() {
    return (select(expenses)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
  }

  // --- BUDGETS DAO ---
  Future<int> insertBudget(BudgetsCompanion budget) => into(budgets).insert(budget);
  Stream<List<Budget>> watchBudgets() => select(budgets).watch();
}
