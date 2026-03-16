import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/expense/data/datasources/database.dart';

// Ce provider crée une instance unique de la base de données accessible partout
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();

  // ACTION CLÉ : On lance le traitement des récurrents dès que la DB est créée
  // On ne bloque pas l'UI avec 'await' ici pour un démarrage rapide,
  // mais en prod on pourrait attendre.
  db.processRecurringExpenses();

  return db;
});
