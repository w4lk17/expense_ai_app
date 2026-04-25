import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:expense_ai_app/features/expense/data/datasources/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // On utilise une base en mémoire pour les tests (rapide et isolé)
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Database Tests', () {
    test('Seed Data: Les catégories par défaut doivent être créées', () async {
      // Quand on lance la base, le "onCreate" ou la migration doit tourner
      // Avec NativeDatabase.memory(), la base est vide, onCreate est appelé.

      final categories = await db.getAllCategories();

      // On vérifie qu'on a bien nos 6 catégories
      expect(categories.length, 6);
      expect(categories.any((c) => c.name == 'Alimentation'), isTrue);
    });

    test('CRUD: On peut insérer et lire une dépense', () async {
      // 1. Récupérer une catégorie (nécessaire pour la clé étrangère)
      final categories = await db.getAllCategories();
      final alimentation = categories.firstWhere(
        (c) => c.name == 'Alimentation',
      );

      // 2. Insérer une dépense
      final expenseId = await db.insertExpense(
        ExpensesCompanion.insert(
          amount: Value(15.50).value,
          categoryId: Value(alimentation.id),
          date: DateTime.now(),
        ),
      );

      // 3. Vérifier l'ID retourné
      expect(expenseId, greaterThan(0));

      // 4. Vérifier la lecture via Stream (pour simuler l'UI)
      // final expenses = await db.watchAllExpenses().first;
      // expect(expenses.length, 1);
      // expect(expenses.first.amount, 15.50);
    });
  });
}
