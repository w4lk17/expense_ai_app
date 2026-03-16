import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/themes/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/expense/presentation/pages/home_shell.dart';

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
      // On écoute l'état de l'authentification
      home: ref.watch(authStateProvider).when(
        data: (authState) {
          final session = authState.session;
          // Si session existe -> App, sinon -> Login
          if (session != null) {
            return const HomeShell();
          } else {
            return const LoginPage();
          }
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(body: Center(child: Text('Erreur Auth: $e'))),
      ),
    );
  }
}