import 'package:drift/drift.dart';
import 'package:drift/drift.dart' as drift;

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
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceInterval =>
      text().nullable().withDefault(const Constant('monthly'))(); // 'monthly', 'weekly'
  DateTimeColumn get nextRecurrenceDate => dateTime().nullable()(); // Date de la prochaine génération
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

// Cette classe contient une dépense ET sa catégorie associée
class ExpenseWithCategory {
  final Expense expense;
  final Category? category;

  ExpenseWithCategory(this.expense, this.category);
}

@DriftDatabase(tables: [Categories, Expenses, Budgets])
class AppDatabase extends _$AppDatabase {
  // On accepte un executor externe pour les tests
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 3; // INCREMENTATION (on passe de 2 à 3)

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
            CategoriesCompanion.insert(
              name: 'Alimentation',
              color: const Value(0xFFFF9800),
              icon: const Value(0xe56c),
            ), // restaurant
            CategoriesCompanion.insert(
              name: 'Transport',
              color: const Value(0xFF2196F3),
              icon: const Value(0xe531),
            ), // directions_car
            CategoriesCompanion.insert(
              name: 'Logement',
              color: const Value(0xFF9C27B0),
              icon: const Value(0xe88a),
            ), // home
            CategoriesCompanion.insert(
              name: 'Loisirs',
              color: const Value(0xFF4CAF50),
              icon: const Value(0xe40f),
            ), // movie
            CategoriesCompanion.insert(
              name: 'Santé',
              color: const Value(0xFFF44336),
              icon: const Value(0xe86d),
            ), // medical_services
            CategoriesCompanion.insert(
              name: 'Autre',
              color: const Value(0xFF607D8B),
              icon: const Value(0xe5d3),
            ), // category
          ]);
        });
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Gestion des migrations futures
        if (from < 2) {
          await m.createTable(budgets);
        }
        if (from < 3) {
          // Ajout des colonnes récurrentes
          await m.addColumn(expenses, expenses.isRecurring);
          await m.addColumn(expenses, expenses.recurrenceInterval);
          await m.addColumn(expenses, expenses.nextRecurrenceDate);
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
  Future<void> updateExpense(Expense expense) async {
    await update(expenses).replace(expense);
  }

  Future<int> deleteExpense(Expense expense) => delete(expenses).delete(expense);
  Stream<List<ExpenseWithCategory>> watchAllExpensesWithCategory() {
    final query = select(expenses).join([leftOuterJoin(categories, categories.id.equalsExp(expenses.categoryId))]);

    // On trie par date décroissante
    query.orderBy([OrderingTerm.desc(expenses.date)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final expense = row.readTable(expenses);
        final category = row.readTableOrNull(categories); // Peut être null
        return ExpenseWithCategory(expense, category);
      }).toList();
    });
  }

  Future<List<Expense>> getUnsyncedExpenses() {
    return (select(expenses)..where((t) => t.isSynced.equals(false))).get();
  }

  Future<void> updateSyncStatus(int id, bool isSynced) {
    return (update(
      expenses,
    )..where((t) => t.id.equals(id))).write(ExpensesCompanion(isSynced: drift.Value(isSynced)));
  }

  // Récupère les dépenses récurrentes dont la date de prochaine échéance est dépassée
  Future<List<Expense>> getDueRecurringExpenses(DateTime now) {
    return (select(
      expenses,
    )..where((t) => t.isRecurring.equals(true) & t.nextRecurrenceDate.isSmallerOrEqualValue(now))).get();
  }

  // Met à jour la prochaine date de récurrence pour une dépense
  Future<void> updateNextRecurrenceDate(int id, DateTime nextDate) {
    return (update(
      expenses,
    )..where((t) => t.id.equals(id))).write(ExpensesCompanion(nextRecurrenceDate: Value(nextDate)));
  }

  // LA MÉTHODE PRINCIPALE À APPELER AU DÉMARRAGE
  Future<void> processRecurringExpenses() async {
    final now = DateTime.now();
    // On récupère toutes les échéances dépassées
    final dueExpenses = await getDueRecurringExpenses(now);

    for (var expense in dueExpenses) {
      // 1. Créer une NOUVELLE dépense (la copie pour ce mois-ci)
      // La date de la nouvelle dépense = la date de prochaine échéance
      final newExpense = ExpensesCompanion.insert(
        amount: expense.amount,
        description: Value(expense.description),
        categoryId: Value(expense.categoryId),
        date: expense.nextRecurrenceDate!, // La date est l'ancienne "next date"
        paymentMethod: Value(expense.paymentMethod),
        isRecurring: const Value(false),
      );

      await into(expenses).insert(newExpense);

      // Calcul de la nouvelle date pour l'originale (+1 mois)
      final currentNext = expense.nextRecurrenceDate!;
      final newNextDate = DateTime(currentNext.year, currentNext.month + 1, currentNext.day);

      await updateNextRecurrenceDate(expense.id, newNextDate);
    }
  }

  // --- BUDGETS DAO ---
  // Récupérer le budget d'une catégorie pour un mois/année précis
  Future<Budget?> getBudget(int categoryId, int month, int year) {
    return (select(budgets)
          ..where((t) => t.categoryId.equals(categoryId) & t.month.equals(month) & t.year.equals(year)))
        .getSingleOrNull();
  }

  // Sauvegarder ou mettre à jour un budget (Upsert manuel)
  Future<void> saveBudget(BudgetsCompanion budget) async {
    // On regarde si un budget existe déjà pour cette catégorie/mois/année
    final existing = await getBudget(budget.categoryId.value!, budget.month.value!, budget.year.value!);

    if (existing != null) {
      // Update
      await (update(budgets)..where((t) => t.id.equals(existing.id))).write(budget);
    } else {
      // Insert
      await into(budgets).insert(budget);
    }
  }

  // Récupérer tous les budgets du mois courant
  Future<List<Budget>> getCurrentMonthBudgets() async {
    final now = DateTime.now();
    return (select(budgets)..where((t) => t.month.equals(now.month) & t.year.equals(now.year))).get();
  }
}
