import 'package:expense_ai_app/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation de Supabase
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    debug: true, // Passer à false en production
  );
  // 2. Lancement de l'application avec Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Expense AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: Center(child: Text("Setup Terminé - Prêt pour la Phase 1.2"))),
    );
  }
}
