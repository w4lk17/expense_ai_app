import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/expense/data/datasources/database.dart';

// Ce provider crée une instance unique de la base de données accessible partout
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
