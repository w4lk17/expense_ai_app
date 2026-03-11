// lib/features/expense/data/datasources/database.dart

import 'package:drift/drift.dart';

import '../../../../core/database/connection.dart';

part 'database.g.dart';

// Définition de la table des Catégories
// Une catégorie contient un nom, une icône et une couleur
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get color => integer().nullable()(); // Stockage de la couleur en int (0xFF...)
  IntColumn get icon => integer().nullable()(); // Stockage du code icône
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Définition de la table des Dépenses
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()(); // Le montant (float/double)
  TextColumn get description => text().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get paymentMethod => text().nullable()(); // Ex: "Carte", "Espèce"
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); // Pour la synchro Supabase plus tard
}

// 2. Définition de la base de données
@DriftDatabase(tables: [Categories, Expenses])
class AppDatabase extends _$AppDatabase {
  // On appelle le constructeur parent avec notre connexion ouverte
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;
}
