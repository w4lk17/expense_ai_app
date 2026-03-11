import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// On importera le fichier généré plus tard, pour l'instant on prépare le terrain

// Cette fonction ouvre la base de données
LazyDatabase openConnection() {
  // La méthode LazyDatabase permet d'ouvrir la connexion seulement quand c'est nécessaire
  return LazyDatabase(() async {
    // On récupère le dossier de stockage de l'application
    final dbFolder = await getApplicationDocumentsDirectory();

    // On crée le fichier de la base de données
    final file = File(p.join(dbFolder.path, 'expense_ai.db'));

    // On retourne une connexion native SQLite
    return NativeDatabase.createInBackground(file);
  });
}
